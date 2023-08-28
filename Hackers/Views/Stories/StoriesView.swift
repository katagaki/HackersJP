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
    @State var selectedStory: HNItemLocalizable? = nil
    @State var progressText: String = "準備中…"
    @State var errorText: String = ""
    @State var currentPage: Int = 0
    @State var storyCount: Int = 0

    var body: some View {
        NavigationStack {
            storyList()
            .task {
                if state == .initialized {
                    do {
                        state = .loadingInitialData
                        progressText = "翻訳用リソースをダウンロード中…"
                        try await translator.downloadModelIfNeeded()
                        progressText = "記事を読み込み中…"
                        await refreshStories()
                        progressText = ""
                        state = .readyForInteraction
                    } catch {
                        errorText = error.localizedDescription
                        state = .initialized
                    }
                }
            }
            .refreshable {
                await refreshStories(useCache: false)
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
                          totalPages: .constant((Int(ceil(Double(storyCount) /
                                                          Double(settings.pageStoryCount)))))) {
                    Task {
                        currentPage -= 1
                        await refreshStoriesWithProgress()
                    }
                } nextAction: {
                    Task {
                        currentPage += 1
                        await refreshStoriesWithProgress()
                    }
                }
                .disabled(progressText != "")
                .background(.regularMaterial,
                            in: RoundedRectangle(cornerRadius: 99, style: .continuous))
                .padding()
            }
            .overlay {
                if errorText != "" {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.largeTitle)
                        Text(errorText)
                    }
                } else if progressText != "" {
                    VStack(alignment: .center, spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text(progressText)
                    }
                }
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
                        await refreshStoriesWithProgress()
                    }
                }
            })
            .onChange(of: settings.pageStoryCount, perform: { _ in
                Task {
                    currentPage = 0
                    await refreshStoriesWithProgress()
                }
            })
            .navigationTitle(type.getConfig().viewTitle)
        }
    }

    func refreshStoriesWithProgress() async {
        switch type {
        case .top, .new, .best:
            stories.feed.removeAll()
        case .show:
            stories.showStories.removeAll()
        case .job:
            stories.jobs.removeAll()
        }
        progressText = "記事を読み込み中…"
        await refreshStories()
        progressText = ""
    }

    func refreshStories(useCache: Bool = true) async {
        do {
            errorText = ""
            let jsonURL = "\(apiEndpoint)/\(type.getConfig().jsonName).json"
            let storyIDs = try await AF.request(jsonURL, method: .get)
                .serializingDecodable([Int].self,
                                      decoder: JSONDecoder()).value
            storyCount = storyIDs.count
            let fetchedStories = await withTaskGroup(of: HNItemLocalizable?.self,
                                          returning: [HNItemLocalizable].self, body: { group in
                var stories: [HNItemLocalizable] = []
                let currentStartingIndex = currentPage * settings.pageStoryCount
                for storyID in storyIDs[currentStartingIndex..<min(storyIDs.count, currentStartingIndex + settings.pageStoryCount)] {
                    group.addTask {
                        if useCache {
                            if let cachedStory = await miniCache.item(for: storyID) {
                                return cachedStory
                            }
                        }
                        do {
                            let storyItem = try await AF.request("\(apiEndpoint)/item/\(storyID).json",
                                                                 method: .get)
                                .serializingDecodable(HNItem.self,
                                                      decoder: JSONDecoder()).value
                            var newLocalizableItem = HNItemLocalizable(item: storyItem)
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
                            if let textDeformatted = newLocalizableItem.textDeformatted() {
                                newLocalizableItem.textLocalized = try await translator
                                    .translate(textDeformatted)
                            } else {
                                newLocalizableItem.textLocalized = try await translator
                                    .translate(storyItem.text ?? "")
                            }
                            newLocalizableItem.cacheDate = Date()
                            return newLocalizableItem
                        } catch {
                            return nil
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
            switch type {
            case .top, .new, .best:
                for story in stories.feed {
                    miniCache.cache(newItem: story)
                }
                stories.feed = fetchedStories
            case .show:
                for story in stories.showStories {
                    miniCache.cache(newItem: story)
                }
                stories.showStories = fetchedStories
            case .job:
                for story in stories.jobs {
                    miniCache.cache(newItem: story)
                }
                stories.jobs = fetchedStories
            }
        } catch {
            errorText = error.localizedDescription
        }
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
