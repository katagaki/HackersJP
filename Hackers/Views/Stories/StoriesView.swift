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
            .onDisappear {
                cacheStories()
            }
            .refreshable {
                if state == .readyForInteraction {
                    do {
                        state = .loadingInitialData
                        try await refreshStoryIDs()
                        await refreshStories(useCache: false)
                        currentPage = 0
                        state = .readyForInteraction
                    } catch {
                        overlayMode = .error
                        overlayText = error.localizedDescription
                        state = .initialized
                    }
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
                        isOverlayShowing = true
                        currentPage -= 1
                        cacheStories()
                        await refreshStories()
                        isOverlayShowing = false
                    }
                } nextAction: {
                    Task {
                        isOverlayShowing = true
                        currentPage += 1
                        cacheStories()
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
                        Overlay(overlayMode: $overlayMode,
                                overlayText: $overlayText,
                                overlayCurrent: $overlayCurrent,
                                overlayTotal: $overlayTotal)
                    }
                }
                .animation(.default, value: isOverlayShowing)
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
            .onChange(of: settings.feedSort, perform: { _ in
                Task {
                    isOverlayShowing = true
                    currentPage = 0
                    if type == .top || type == .new || type == .best {
                        type = settings.feedSort
                        await refreshStories()
                    }
                    isOverlayShowing = false
                }
            })
            .onChange(of: settings.pageStoryCount, perform: { _ in
                Task {
                    isOverlayShowing = true
                    currentPage = 0
                    await refreshStories()
                    isOverlayShowing = false
                }
            })
            .listStyle(.plain)
            .navigationTitle(type.getConfig().viewTitle)
        }
    }

    func refreshStoryIDs() async throws {
        overlayMode = .progress
        overlayText = "記事を読み込み中…"
        overlayCurrent = 0
        overlayTotal = 1
        let jsonURL = "\(apiEndpoint)/\(type.getConfig().jsonName).json"
        storyIDs = try await AF.request(jsonURL, method: .get)
            .serializingDecodable([Int].self,
                                  decoder: JSONDecoder()).value
        overlayCurrent = 1
        overlayTotal = 1
        overlayText = ""
    }

    func refreshStories(useCache: Bool = true) async {
        overlayMode = .progress
        overlayText = "記事内容を読み込み中…"
        overlayCurrent = 0
        overlayTotal = 0
        let fetchedStories = await withTaskGroup(of: HNItemLocalizable?.self,
                                      returning: [HNItemLocalizable].self, body: { group in
            var stories: [HNItemLocalizable] = []
            let currentStartingIndex = currentPage * settings.pageStoryCount
            overlayTotal = settings.pageStoryCount
            for storyID in storyIDs[currentStartingIndex..<min(storyIDs.count, currentStartingIndex + settings.pageStoryCount)] {
                group.addTask(priority: .high) {
                    if useCache,
                       var cachedStory = await miniCache.item(for: storyID) {
                        debugPrint("[\(storyID)] Using cache...")
                        cachedStory.requiresCaching = false
                        DispatchQueue.main.async {
                            overlayCurrent += 1
                        }
                        return cachedStory
                    } else {
                        do {
                            debugPrint("[\(storyID)] Fetching story...")
                            var newLocalizableItem = try await fetchStory(storyID: storyID)
                            debugPrint("[\(storyID)] Setting cache date...")
                            newLocalizableItem.requiresCaching = true
                            newLocalizableItem.cacheDate = Date()
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
        cacheStories()
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
    
    func fetchStory(storyID: Int) async throws -> HNItemLocalizable {
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
        return newLocalizableItem
    }

    func downloadTranslationModel() async throws {
        overlayMode = .progress
        overlayText = "翻訳用リソースをダウンロード中…"
        overlayCurrent = 0
        overlayTotal = 1
        try await translator.downloadModelIfNeeded()
        overlayCurrent = 1
        overlayTotal = 1
        overlayText = ""
    }

    func cacheStories() {
        miniCache.cache(newItems: stories.feed.filter { story in
            story.requiresCaching
        })
        miniCache.cache(newItems: stories.jobs.filter { story in
            story.requiresCaching
        })
        miniCache.cache(newItems: stories.showStories.filter { story in
            story.requiresCaching
        })
        stories.setRequiresCachingToFalseForAll()
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
}
