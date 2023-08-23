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

    let translator = Translator.translator(
        options: TranslatorOptions(sourceLanguage: .english,
                                   targetLanguage: .japanese))

    @State var type: HNStoryType
    @State var stories: [HNItemLocalizable] = []
    @State var selectedStory: HNItemLocalizable? = nil
    @State var progressText: String = "準備中…"
    @State var errorText: String = ""
    @State var isFirstLoadCompleted: Bool = false
    @State var isTranslateEnabled: Bool = true

    var body: some View {
        NavigationStack {
            List(stories, id: \.item.id, rowContent: { story in
                Button {
                    selectedStory = story
                } label: {
                    HStack {
                        StoryItemView(story: story,
                                      isTranslateEnabled: $isTranslateEnabled)
                        Spacer()
                    }
                }
                .contentShape(Rectangle())
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
                await refreshStories()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isTranslateEnabled && progressText == "" {
                        Image("TranslateBanner")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(alignment: .center, spacing: 8.0) {
                        Menu("表示設定") {
                            ControlGroup {
                                Button {
                                    isTranslateEnabled = true
                                } label: {
#if swift(>=5.9)
                                    if #available(iOS 17, *) {
                                        Image(uiImage: UIImage(
                                            systemName: "textformat.size",
                                            withConfiguration: .init(locale:
                                                    .init(identifier: "ja-JP")))!)
                                    }
#endif
                                    Text("日本語")
                                }
                                Button {
                                    isTranslateEnabled = false
                                } label: {
#if swift(>=5.9)
                                    if #available(iOS 17, *) {
                                        Image(uiImage: UIImage(
                                            systemName: "textformat.size",
                                            withConfiguration: .init(locale:
                                                    .init(identifier: "en-US")))!)
                                    }
#endif
                                    Text("英語（原文）")
                                }
                            } label: {
                                Text("言語")
                            }
                            if type == .top || type == .new || type == .best {
                                ControlGroup {
                                    Button {
                                        Task {
                                            type = .top
                                            await refreshStoriesWithProgress()
                                        }
                                    } label: {
                                        Image(systemName: "flame")
                                        Text("トップ")
                                    }
                                    Button {
                                        Task {
                                            type = .new
                                            await refreshStoriesWithProgress()
                                        }
                                    } label: {
                                        Image(systemName: "clock")
                                        Text("新しい順")
                                    }
                                    Button {
                                        Task {
                                            type = .best
                                            await refreshStoriesWithProgress()
                                        }
                                    } label: {
                                        Image(systemName: "trophy")
                                        Text("ベスト")
                                    }
                                } label: {
                                    Text("並べ替え")
                                }
                            }
                        }
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
                if isTranslateEnabled {
                    SafariView(url: URL(string: story.urlTranslated())!)
                        .ignoresSafeArea()
                } else {
                    SafariView(url: URL(string: story.item.url!)!)
                        .ignoresSafeArea()
                }
            })
            .listStyle(.plain)
            .navigationTitle(type.getConfig().viewTitle)
        }
    }
    
    func refreshStoriesWithProgress() async {
        stories.removeAll()
        progressText = "記事を読み込み中…"
        await refreshStories()
        progressText = ""
    }
    
    func refreshStories() async {
        do {
            errorText = ""
            let storyIDs = try await AF.request("\(apiEndpoint)/\(type.getConfig().jsonName).json",
                                                method: .get)
                .serializingDecodable([Int].self,
                                      decoder: JSONDecoder()).value
            stories = await withTaskGroup(of: HNItemLocalizable?.self, 
                                          returning: [HNItemLocalizable].self, body: { group in
                var stories: [HNItemLocalizable] = []
                for storyID in storyIDs[0..<30] {
                    group.addTask {
                        do {
                            var storyItem = try await AF.request("\(apiEndpoint)/item/\(storyID).json",
                                                                 method: .get)
                                .serializingDecodable(HNItem.self,
                                                      decoder: JSONDecoder()).value
                            switch type {
                            case .show:
                                storyItem.title = storyItem.title?.replacingOccurrences(of: "Show HN: ", with: "")
                            default: break
                            }
                            var newLocalizableItem = HNItemLocalizable(
                                titleLocalized: "",
                                item: storyItem)
                            newLocalizableItem.titleLocalized = try await translator
                                .translate(storyItem.title ?? "")
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
