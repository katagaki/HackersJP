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
    @EnvironmentObject var settings: SettingsManager

    let translator = Translator.translator(
        options: TranslatorOptions(sourceLanguage: .english,
                                   targetLanguage: .japanese))

    @State var state: ViewState = .initialized
    @State var type: HNStoryType
    @State var storyIDs: [Int] = []
    @State var displayedStories: [HNItemLocalizable] = []
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

    func refreshAll() async {
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

    func refreshStoryIDs() async throws {
        setOverlay("記事を読み込み中…", .progress, 0, 1)
        let jsonURL = "\(apiEndpoint)/\(type.getConfig().jsonName).json"
        storyIDs = try await AF.request(jsonURL, method: .get)
            .serializingDecodable([Int].self,
                                  decoder: JSONDecoder()).value
        setOverlay("記事を読み込み中…", .progress, 1, 1)
    }

    func refreshStories(forPage page: Int, useCache: Bool = true) async {
        let currentStartingIndex = page * settings.pageStoryCount
        let lastPageToFetch = min(storyIDs.count, currentStartingIndex + settings.pageStoryCount)
        let idsToFetch = Array(storyIDs[currentStartingIndex..<lastPageToFetch])
        setOverlay("記事内容を読み込み中…", .progress, 0, idsToFetch.count)
        displayedStories = await stories.fetchStories(ids: idsToFetch,
                                                      translator: translator,
                                                      fetchFreshStory: !useCache) {
            overlayCurrent += 1
        }
    }

    func downloadTranslationModel() async throws {
        setOverlay("翻訳用リソースをダウンロード中…", .progress, 0, 1)
        try await translator.downloadModelIfNeeded()
        setOverlay("翻訳用リソースをダウンロード中…", .progress, 1, 1)
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

    @ViewBuilder
    func storyList() -> some View {
        ScrollViewReader { scrollView in
            List {
                ForEach($displayedStories) { $story in
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
                }
            }
            .listStyle(.plain)
            .navigationDestination(for: HNItemLocalizable.self, destination: { story in
                StoryView(story: story)
            })
            .refreshable {
                await refreshAll()
            }
            .safeAreaInset(edge: .bottom, alignment: .center) {
                paginator()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if settings.titleLanguage == 0 {
                        Image("TranslateBanner")
                    }
                }
            }
            .onChange(of: currentPage) { _ in
                if let firstStory = displayedStories.first {
                    scrollView.scrollTo(firstStory.id)
                }
            }
        }
        .navigationTitle(type.getConfig().viewTitle)
    }

    @ViewBuilder
    func paginator() -> some View {
        Paginator(currentPage: $currentPage,
                  totalPages: .constant((Int(ceil(Double(storyIDs.count) /
                                                  Double(settings.pageStoryCount)))))) {
            Task {
                isOverlayShowing = true
                await refreshStories(forPage: currentPage - 1)
                currentPage -= 1
                isOverlayShowing = false
            }
        } nextAction: {
            Task {
                isOverlayShowing = true
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
}
