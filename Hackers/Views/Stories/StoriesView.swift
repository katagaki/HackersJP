//
//  StoriesView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Alamofire
import FaviconFinder
import MLKitTranslate
import SwiftUI

struct StoriesView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var stories: StoryManager
    @EnvironmentObject var miniCache: CacheManager
    @EnvironmentObject var settings: SettingsManager

    let translator = Translator.translator(
        options: TranslatorOptions(sourceLanguage: .english,
                                   targetLanguage: .japanese))

    @State var state: ViewState = .initialized
    @State var type: HNStoryType
    @State var storyIDs: [Int] = []
    @State var selectedStory: HNItemLocalizable?
    @State var isOverlayShowing: Bool = false
    @State var overlayMode: OverlayMode = .progress
    @State var overlayText: String = "準備中…"
    @State var overlayCurrent: Int = 0
    @State var overlayTotal: Int = 0
    @State var currentPage: Int = 0

    var body: some View {
        navigationStack()
            .task {
                if state == .initialized {
                    do {
                        state = .loadingInitialData
                        isOverlayShowing = true
                        try await downloadTranslationModel()
                        try await refreshStoryIDs()
                        await refreshStories(forPage: currentPage)
                        isOverlayShowing = false
                        state = .readyForInteraction
                    } catch {
                        overlayMode = .error
                        overlayText = error.localizedDescription
                        state = .initialized
                    }
                }
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
                .animation(.default.speed(1.5), value: isOverlayShowing)
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
                    if type == .top || type == .new || type == .best {
                        type = settings.feedSort
                        await refreshStories(forPage: 0)
                        currentPage = 0
                    }
                    isOverlayShowing = false
                }
            })
            .onChange(of: settings.pageStoryCount, perform: { _ in
                Task {
                    isOverlayShowing = true
                    await refreshStories(forPage: 0)
                    currentPage = 0
                    isOverlayShowing = false
                }
            })
    }

    func refreshStoryIDs() async throws {
        setOverlay("記事を読み込み中…", .progress, 0, 1)
        let jsonURL = "\(apiEndpoint)/\(type.getConfig().jsonName).json"
        storyIDs = try await AF.request(jsonURL, method: .get)
            .serializingDecodable([Int].self,
                                  decoder: JSONDecoder()).value
        setOverlay("記事を読み込み中…", .progress, 1, 1)
    }

    func refreshStories(forPage page: Int, useCache: Bool = true) async {
        setOverlay("記事内容を読み込み中…", .progress, 0, 0)
        let fetchedStories = await withTaskGroup(of: HNItemLocalizable?.self,
                                      returning: [HNItemLocalizable].self, body: { group in
            var stories: [HNItemLocalizable] = []
            let currentStartingIndex = page * settings.pageStoryCount
            let lastPageToFetch = min(storyIDs.count, currentStartingIndex + settings.pageStoryCount)
            overlayTotal = settings.pageStoryCount
            for storyID in storyIDs[currentStartingIndex..<lastPageToFetch] {
                group.addTask(priority: .high) {
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
                            let newLocalizableItem = try await fetchStory(storyID: storyID)
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
        stories.storiesPendingCache.append(contentsOf: fetchedStories)
        switch type {
        case .top, .new, .best:
            stories.feed = fetchedStories
        case .show:
            stories.showStories = fetchedStories
        case .job:
            stories.jobs = fetchedStories
        }
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
        debugPrint("[\(storyID)] Getting favicon...")
        if let url = storyItem.url {
            do {
                let fetchedFavicon = try await FaviconFinder(
                    url: URL(string: url)!,
                    preferredType: .html,
                    preferences: [
                        .html: FaviconType.appleTouchIconPrecomposed.rawValue,
                        .ico: "favicon.ico",
                        .webApplicationManifestFile: FaviconType.launcherIcon4x.rawValue
                    ],
                    downloadImage: false,
                    logEnabled: true
                ).downloadFavicon()
                newLocalizableItem.faviconURL = fetchedFavicon.url.absoluteString
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return newLocalizableItem
    }

    func downloadTranslationModel() async throws {
        setOverlay("翻訳用リソースをダウンロード中…", .progress, 0, 1)
        try await translator.downloadModelIfNeeded()
        setOverlay("翻訳用リソースをダウンロード中…", .progress, 1, 1)
    }

    func cacheStories() {
        let numberOfStoriesToCache = stories.storiesPendingCache.count
        setOverlay("キャッシュ中…", .progress, 0, numberOfStoriesToCache)
        miniCache.cache(newItems: stories.storiesPendingCache)
        setOverlay("キャッシュ中…", .progress, numberOfStoriesToCache, numberOfStoriesToCache)
    }

    func setOverlay(_ text: String, _ mode: OverlayMode, _ current: Int, _ total: Int) {
        overlayMode = mode
        overlayText = text
        overlayCurrent = current
        overlayTotal = total
    }

    @ViewBuilder
    func navigationStack() -> some View {
        switch type {
        case .show:
            NavigationStack(path: $navigationManager.showTabPath) {
                storyList()
                    .listStyle(.plain)
                    .navigationTitle(type.getConfig().viewTitle)
            }
        case .job:
            NavigationStack(path: $navigationManager.jobsTabPath) {
                storyList()
                    .listStyle(.plain)
                    .navigationTitle(type.getConfig().viewTitle)
            }
        default:
            NavigationStack(path: $navigationManager.feedTabPath) {
                storyList()
                    .listStyle(.plain)
                    .navigationTitle(type.getConfig().viewTitle)
            }
        }
    }

    // swiftlint:disable function_body_length
    @ViewBuilder
    func storyList() -> some View {
        ScrollViewReader { scrollView in
            Group {
                switch type {
                case .job:
                    List($stories.jobs, rowContent: { $story in
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
                            NavigationLink(value: story) {
                                StoryItemRow(story: $story)
                            }
                        }
                    })
                case .show:
                    List($stories.showStories, rowContent: { $story in
                        NavigationLink(value: story) {
                            StoryItemRow(story: $story)
                        }
                    })
                default:
                    List($stories.feed, rowContent: { $story in
                        NavigationLink(value: story) {
                            StoryItemRow(story: $story)
                        }
                    })
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: HNItemLocalizable.self, destination: { story in
                StoryView(story: story)
            })
            .onDisappear {
                cacheStories()
            }
            .refreshable {
                if state == .readyForInteraction {
                    do {
                        state = .loadingInitialData
                        try await refreshStoryIDs()
                        await refreshStories(forPage: 0, useCache: false)
                        currentPage = 0
                        state = .readyForInteraction
                    } catch {
                        overlayMode = .error
                        overlayText = error.localizedDescription
                        state = .initialized
                    }
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .center) {
                Paginator(currentPage: $currentPage,
                          totalPages: .constant((Int(ceil(Double(storyIDs.count) /
                                                          Double(settings.pageStoryCount)))))) {
                    Task {
                        isOverlayShowing = true
                        cacheStories()
                        await refreshStories(forPage: currentPage - 1)
                        currentPage -= 1
                        isOverlayShowing = false
                    }
                } nextAction: {
                    Task {
                        isOverlayShowing = true
                        cacheStories()
                        await refreshStories(forPage: currentPage + 1)
                        currentPage += 1
                        isOverlayShowing = false
                    }
                }
                .disabled(isOverlayShowing)
                .background(.regularMaterial,
                            in: RoundedRectangle(cornerRadius: 99, style: .continuous))
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if settings.titleLanguage == 0 {
                        Image("TranslateBanner")
                    }
                }
            }
            .onChange(of: currentPage) { _ in
                switch type {
                case .show:
                    scrollView.scrollTo(stories.showStories.first!.id)
                case .job:
                    scrollView.scrollTo(stories.jobs.first!.id)
                default:
                    scrollView.scrollTo(stories.feed.first!.id)
                }
            }
        }
        .navigationTitle(type.getConfig().viewTitle)
    }
    // swiftlint:enable function_body_length
}
