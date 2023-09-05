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
    @State var footerMode: FooterDisplayMode = .progress
    @State var footerText: String = "準備中…"
    @State var footerCurrent: Int = 0
    @State var footerTotal: Int = 0
    @State var currentPage: Int = 0

    var body: some View {
        navigationStack()
            .task {
                if state == .initialized {
                    await refreshAll()
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
            .onChange(of: settings.feedSort, perform: { _ in
                Task {
                    if type == .top || type == .new || type == .best {
                        type = settings.feedSort
                        await refreshAll()
                    }
                }
            })
            .onChange(of: settings.pageStoryCount, perform: { _ in
                Task {
                    await refreshAll()
                }
            })
    }

    func refreshAll(usingCache useCache: Bool = true) async {
        do {
            state = .loadingInitialData
            displayedStories.removeAll()
            try await refreshStoryIDs()
            currentPage = 0
            await refreshStories(forPage: currentPage, useCache: useCache)
            state = .readyForInteraction
        } catch {
            footerMode = .error
            footerText = error.localizedDescription
            state = .initialized
        }
    }

    func refreshStoryIDs() async throws {
        setFooter("記事を読み込み中…", .progress, 0, 1)
        let jsonURL = "\(apiEndpoint)/\(type.getConfig().jsonName).json"
        storyIDs = try await AF.request(jsonURL, method: .get)
            .serializingDecodable([Int].self,
                                  decoder: JSONDecoder()).value
        setFooter("記事を読み込み中…", .progress, 1, 1)
    }

    func refreshStories(forPage page: Int, useCache: Bool = true) async {
        let currentStartingIndex = page * settings.pageStoryCount
        let lastPageToFetch = min(storyIDs.count, currentStartingIndex + settings.pageStoryCount)
        debugPrint("Loading stories from index \(currentStartingIndex) to \(lastPageToFetch)...")
        let idsToFetch = Array(storyIDs[currentStartingIndex..<lastPageToFetch])
        setFooter("記事内容を読み込み中…", .progress, 0, idsToFetch.count)
        let newlyFetchedStories = await stories.fetchStories(ids: idsToFetch,
                                                             translator: translator,
                                                             fetchFreshStory: !useCache) {
            footerCurrent += 1
        }
        displayedStories.append(contentsOf: newlyFetchedStories)
    }

    func downloadTranslationModel() async throws {
        setFooter("翻訳用リソースをダウンロード中…", .progress, 0, 1)
        try await translator.downloadModelIfNeeded()
        setFooter("翻訳用リソースをダウンロード中…", .progress, 1, 1)
    }

    func setFooter(_ text: String, _ mode: FooterDisplayMode, _ current: Int, _ total: Int) {
        footerMode = mode
        footerText = text
        footerCurrent = current
        footerTotal = total
    }

    func totalNumberOfPages() -> Int {
        return Int(ceil(Double(storyIDs.count) / Double(settings.pageStoryCount)))
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
        List {
            ForEach($displayedStories) { $story in
                if type == .job, story.item.url != nil {
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
            if storyIDs.count == 0 || currentPage < totalNumberOfPages() - 1 {
                ListFooter(footerMode: $footerMode,
                           footerText: $footerText,
                           footerCurrent: $footerCurrent,
                           footerTotal: $footerTotal)
                .listRowSeparator(.hidden)
                .task {
                    if storyIDs.count > 0 && state == .readyForInteraction && currentPage < totalNumberOfPages() - 1 {
                        state = .loadingIntermediaryData
                        currentPage += 1
                        await refreshStories(forPage: currentPage)
                        state = .readyForInteraction
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: HNItemLocalizable.self, destination: { story in
            StoryView(story: story)
        })
        .refreshable {
            if state == .readyForInteraction {
                await refreshAll(usingCache: false)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if settings.titleLanguage == 0 {
                    Image("TranslateBanner")
                }
            }
        }
        .navigationTitle(type.getConfig().viewTitle)
    }
}
