//
//  StoriesView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Alamofire
import MLKitTranslate
import SwiftUI

struct StoriesView: View {

    @EnvironmentObject var stories: StoryManager
    @EnvironmentObject var miniCache: CacheManager
    @EnvironmentObject var settings: SettingsManager

    let translator = Translator.translator(
        options: TranslatorOptions(sourceLanguage: .english,
                                   targetLanguage: .japanese))
    
    @State var state: ViewState = .initialized
    @State var type: HNStoryType
    @State var storyIDs: [Int] = []
    @State var selectedStory: HNItemLocalizable? = nil
    @State var isOverlayShowing: Bool = false
    @State var overlayMode: OverlayMode = .progress
    @State var overlayText: String = "準備中…"
    @State var overlayCurrent: Int = 0
    @State var overlayTotal: Int = 0
    @State var currentPage: Int = 0

    var body: some View {
        NavigationStack {
            storyList()
            .task {
                if state == .initialized {
                    do {
                        state = .loadingInitialData
                        isOverlayShowing = true
                        try await downloadTranslationModel()
                        try await refreshStoryIDs()
                        await refreshStories()
                        isOverlayShowing = false
                        state = .readyForInteraction
                    } catch {
                        overlayMode = .error
                        overlayText = error.localizedDescription
                        state = .initialized
                    }
                }
            }
            .refreshable {
                do {
                    try await refreshStoryIDs()
                    await refreshStories(useCache: false)
                    currentPage = 0
                } catch {
                    overlayMode = .error
                    overlayText = error.localizedDescription
                    state = .initialized
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if settings.titleLanguage == 0 {
                        Image("TranslateBanner")
                    }
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .center) {
                Paginator(currentPage: $currentPage, 
                          totalPages: .constant((Int(ceil(Double(storyIDs.count) /
                                                          Double(settings.pageStoryCount)))))) {
                    Task {
                        currentPage -= 1
                        isOverlayShowing = true
                        await refreshStories()
                        isOverlayShowing = false
                    }
                } nextAction: {
                    Task {
                        currentPage += 1
                        isOverlayShowing = true
                        await refreshStories()
                        isOverlayShowing = false
                    }
                }
                .disabled(isOverlayShowing)
                .background(.regularMaterial,
                            in: RoundedRectangle(cornerRadius: 99, style: .continuous))
                .padding()
            }
            .overlay {
                ZStack {
                    if isOverlayShowing {
                        VStack(alignment: .center, spacing: 8) {
                            switch overlayMode {
                            case .progress:
                                ProgressView(value: Double(overlayCurrent),
                                             total: Double(overlayTotal))
                                .progressViewStyle(.linear)
                                .frame(width: 200.0)
                            case .error:
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .font(.largeTitle)
                            }
                            Text(overlayText)
                                .font(.body)
                            if overlayMode == .progress {
                                Text("\(overlayCurrent) / \(overlayTotal)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                        .padding()
                    }
                }
                .animation(.snappy, value: isOverlayShowing)
            }
            .sheet(item: $selectedStory, onDismiss: {
                selectedStory = nil
            }, content: { story in
                if settings.linkLanguage == 0 {
                    SafariView(url: URL(string: story.urlTranslated())!)
                        .ignoresSafeArea()
                } else {
                    SafariView(url: URL(string: story.item.url!)!)
                        .ignoresSafeArea()
                }
            })
            .listStyle(.plain)
            .onChange(of: settings.feedSort, perform: { _ in
                Task {
                    currentPage = 0
                    if type == .top || type == .new || type == .best {
                        type = settings.feedSort
                        await refreshStories()
                    }
                }
            })
            .onChange(of: settings.pageStoryCount, perform: { _ in
                Task {
                    currentPage = 0
                    await refreshStories()
                }
            })
            .navigationTitle(type.getConfig().viewTitle)
        }
    }

    func refreshStoryIDs() async throws {
        overlayMode = .progress
        overlayText = "記事を読み込み中…"
        let jsonURL = "\(apiEndpoint)/\(type.getConfig().jsonName).json"
        storyIDs = try await AF.request(jsonURL, method: .get)
            .serializingDecodable([Int].self,
                                  decoder: JSONDecoder()).value
        overlayText = ""
    }

    func refreshStories(useCache: Bool = true) async {
        overlayMode = .progress
        overlayText = "記事内容を読み込み中…"
        let fetchedStories = await withTaskGroup(of: HNItemLocalizable?.self,
                                      returning: [HNItemLocalizable].self, body: { group in
            var stories: [HNItemLocalizable] = []
            let currentStartingIndex = currentPage * settings.pageStoryCount
            overlayTotal = settings.pageStoryCount
            for storyID in storyIDs[currentStartingIndex..<min(storyIDs.count, currentStartingIndex + settings.pageStoryCount)] {
                group.addTask {
                    if useCache,
                       let cachedStory = await miniCache.item(for: storyID) {
                        debugPrint("[\(storyID)] Using cache...")
                        DispatchQueue.main.async {
                            overlayCurrent += 1
                        }
                        return cachedStory
                    } else {
                        do {
                            debugPrint("[\(storyID)] Fetching story...")
                            let storyItem = try await AF.request("\(apiEndpoint)/item/\(storyID).json",
                                                                 method: .get)
                                .serializingDecodable(HNItem.self,
                                                      decoder: JSONDecoder()).value
                            debugPrint("[\(storyID)] Creating localizable object...")
                            var newLocalizableItem = HNItemLocalizable(item: storyItem)
                            debugPrint("[\(storyID)] Localizing title...")
                            if let title = newLocalizableItem.item.title {
                                if title.starts(with: "Show HN: ") {
                                    newLocalizableItem.isShowHNStory = true
                                    newLocalizableItem.item.title = title.replacingOccurrences(of: "Show HN: ", with: "")
                                    newLocalizableItem.titleLocalized = try await translator
                                        .translate(title.replacingOccurrences(of: "Show HN: ", with: ""))
                                } else {
                                    newLocalizableItem.titleLocalized = try await translator
                                        .translate(title)
                                }
                            }
                            debugPrint("[\(storyID)] Localizing text...")
                            if let textDeformatted = newLocalizableItem.textDeformatted() {
                                newLocalizableItem.textLocalized = try await translator
                                    .translate(textDeformatted)
                            } else {
                                newLocalizableItem.textLocalized = try await translator
                                    .translate(storyItem.text ?? "")
                            }
                            debugPrint("[\(storyID)] Setting cache date...")
                            newLocalizableItem.cacheDate = Date()
                            await miniCache.cache(newItem: newLocalizableItem)
                            DispatchQueue.main.async {
                                overlayCurrent += 1
                            }
                            return newLocalizableItem
                        } catch {
                            return nil
                        }
                    }
                }
            }
            for await result in group {
                if let result = result {
                    stories.append(result)
                }
            }
            return stories
        })
        overlayCurrent = 0
        overlayTotal = 0
        switch type {
        case .top, .new, .best:
            stories.feed = fetchedStories
        case .show:
            stories.showStories = fetchedStories
        case .job:
            stories.jobs = fetchedStories
        }
        overlayText = ""
    }

    func downloadTranslationModel() async throws {
        overlayMode = .progress
        overlayText = "翻訳用リソースをダウンロード中…"
        try await translator.downloadModelIfNeeded()
        overlayText = ""
    }

    @ViewBuilder
    func storyList() -> some View {
        switch type {
        case .job:
            List($stories.jobs, id: \.item.id, rowContent: { $story in
                if story.item.url != nil {
                    Button {
                        selectedStory = story
                    } label: {
                        HStack {
                            StoryItemRow(story: $story)
                            Spacer()
                        }
                    }
                    .contentShape(Rectangle())
                } else {
                    NavigationLink {
                        StoryView(story: story)
                    } label: {
                        StoryItemRow(story: $story)
                    }
                }
            })
        case .show:
            List($stories.showStories, id: \.item.id, rowContent: { $story in
                NavigationLink {
                    StoryView(story: story)
                } label: {
                    StoryItemRow(story: $story)
                }
            })
        default:
            List($stories.feed, id: \.item.id, rowContent: { $story in
                NavigationLink {
                    StoryView(story: story)
                } label: {
                    StoryItemRow(story: $story)
                }
            })
        }
    }

    enum OverlayMode {
        case progress
        case error
    }
}
