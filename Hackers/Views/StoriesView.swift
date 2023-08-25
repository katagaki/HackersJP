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

    @EnvironmentObject var miniCache: CacheManager
    @EnvironmentObject var settings: SettingsManager

    let translator = Translator.translator(
        options: TranslatorOptions(sourceLanguage: .english,
                                   targetLanguage: .japanese))

    @State var type: HNStoryType
    @State var stories: [HNItemLocalizable] = []
    @State var selectedStory: HNItemLocalizable? = nil
    @State var progressText: String = "準備中…"
    @State var errorText: String = ""
    @State var isFirstLoadCompleted: Bool = false
    @State var currentPage: Int = 0
    @State var storyCount: Int = 0

    var body: some View {
        NavigationStack {
            List(stories, id: \.item.id, rowContent: { story in
                if type == .job {
                    if story.item.url != nil {
                        Button {
                            selectedStory = story
                        } label: {
                            HStack {
                                StoryItemRow(story: story)
                                Spacer()
                            }
                        }
                        .contentShape(Rectangle())
                    } else {
                        NavigationLink {
                            StoryView(story: story)
                        } label: {
                            StoryItemRow(story: story)
                        }
                    }
                } else {
                    NavigationLink {
                        StoryView(story: story)
                    } label: {
                        StoryItemRow(story: story)
                    }
                }
            })
            .task {
                if !isFirstLoadCompleted {
                    do {
                        progressText = "翻訳用リソースをダウンロード中…"
                        try await translator.downloadModelIfNeeded()
                        progressText = "記事を読み込み中…"
                        await refreshStories()
                        progressText = ""
                    } catch {
                        errorText = error.localizedDescription
                    }
                    isFirstLoadCompleted = true
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
                ToolbarItem(placement: .bottomBar) {
                    HStack(alignment: .center, spacing: 2) {
                        Button {
                            Task {
                                currentPage -= 1
                                await refreshStoriesWithProgress()
                            }
                        } label: {
                            Image(systemName: "arrowtriangle.left")
                        }
                        .disabled(!(progressText == "") || currentPage == 0)
                        Spacer()
                        Text("ページ \(currentPage + 1) / \(Int(ceil(Double(storyCount) / Double(settings.pageStoryCount))))")
                        Spacer()
                        Button {
                            Task {
                                currentPage += 1
                                await refreshStoriesWithProgress()
                            }
                        } label: {
                            Image(systemName: "arrowtriangle.right")
                        }
                        .disabled(!(progressText == "") || currentPage + 1 >= Int(ceil(Double(storyCount) / Double(settings.pageStoryCount))))
                    }
                }
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
        stories.removeAll()
        progressText = "記事を読み込み中…"
        await refreshStories()
        progressText = ""
    }

    func refreshStories(useCache: Bool = true) async {
        do {
            errorText = ""
            let jsonURL = "\(apiEndpoint)/\(type.getConfig().jsonName).json"
            debugPrint("Fetching data from \(jsonURL).")
            let storyIDs = try await AF.request(jsonURL, method: .get)
                .serializingDecodable([Int].self,
                                      decoder: JSONDecoder()).value
            storyCount = storyIDs.count
            stories = await withTaskGroup(of: HNItemLocalizable?.self,
                                          returning: [HNItemLocalizable].self, body: { group in
                var stories: [HNItemLocalizable] = []
                let currentStartingIndex = currentPage * settings.pageStoryCount
                for storyID in storyIDs[currentStartingIndex..<min(storyIDs.count, currentStartingIndex + settings.pageStoryCount)] {
                    group.addTask {
                        if useCache {
                            if let cachedStory = await miniCache.item(for: storyID) {
                                debugPrint("Using cache for \(storyID).")
                                return cachedStory
                            }
                        }
                        do {
                            debugPrint("Getting HN item \(storyID).")
                            var storyItem = try await AF.request("\(apiEndpoint)/item/\(storyID).json",
                                                                 method: .get)
                                .serializingDecodable(HNItem.self,
                                                      decoder: JSONDecoder()).value
                            switch await type {
                            case .show:
                                storyItem.title = storyItem.title?.replacingOccurrences(of: "Show HN: ", with: "")
                            default: break
                            }
                            var newLocalizableItem = HNItemLocalizable(item: storyItem)
                            debugPrint("Translating HN item \(storyID).")
                            newLocalizableItem.titleLocalized = try await translator
                                .translate(storyItem.title ?? "")
                            if let textDeformatted = newLocalizableItem.textDeformatted() {
                                newLocalizableItem.textLocalized = try await translator
                                    .translate(textDeformatted)
                            } else {
                                newLocalizableItem.textLocalized = try await translator
                                    .translate(storyItem.text ?? "")
                            }
                            debugPrint("Downloading favicon for HN item \(storyID).")
                            await newLocalizableItem.downloadFavicon()
                            newLocalizableItem.cacheDate = Date()
                            await miniCache.cache(newItem: newLocalizableItem)
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
        } catch {
            errorText = error.localizedDescription
        }
    }
}
