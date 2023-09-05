//
//  StoryView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/25.
//

import Alamofire
import MLKitTranslate
import SwiftUI

struct StoryView: View {

    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var stories: StoryManager

    let translator = Translator.translator(
        options: TranslatorOptions(sourceLanguage: .english,
                                   targetLanguage: .japanese))

    @State var state: ViewState = .initialized
    @State var story: HNItemLocalizable
    @State var comments: [HNItemLocalizable] = []
    @State var progressText: String = "準備中…"
    @State var isSafariViewControllerPresenting: Bool = false

    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 2.0) {
                Text((settings.titleLanguage == 0 ?
                      story.titleLocalized : story.item.title) ?? "")
                .font(.headline)
                .layoutPriority(1)
                .textSelection(.enabled)
                if story.item.text != nil {
                    Text((settings.titleLanguage == 0 ?
                          story.textLocalized : story.textDeformatted() ??
                          story.item.text) ?? "")
                    .font(.subheadline)
                    .layoutPriority(1)
                    .textSelection(.enabled)
                }
                HStack(alignment: .center, spacing: 4.0) {
                    if let hostname = story.hostname() {
                        Text(hostname)
                        Divider()
                    }
                    Text(Date(timeIntervalSince1970: TimeInterval(story.item.time)),
                         style: .relative)
                }
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 8) {
                    if let url = story.item.url {
                        Button {
                            isSafariViewControllerPresenting = true
                        } label: {
                            if let storedFaviconURL = story.faviconURL,
                               let faviconURL = URL(string: storedFaviconURL) {
                                AsyncImage(url: faviconURL) { image in
                                    image
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .fixedSize()
                                        .clipShape(RoundedRectangle(cornerRadius: 2.0))
                                } placeholder: {
                                    Image(systemName: "safari")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .fixedSize()
                                }
                            } else {
                                Image(systemName: "safari")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .fixedSize()
                            }
                            Text("記事を開く")
                        }
                        .buttonBorderShape(.roundedRectangle(radius: 99))
                        .buttonStyle(.borderedProminent)
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                            Text("記事を共有")
                        }
                        .buttonBorderShape(.roundedRectangle(radius: 99))
                        .buttonStyle(.borderedProminent)
                    }
                    ShareLink(item: "https://news.ycombinator.com/item?id=\(story.item.id)") {
                        Image(systemName: "square.and.arrow.up")
                        Text("スレッドを共有")
                    }
                    .buttonBorderShape(.roundedRectangle(radius: 99))
                    .buttonStyle(.borderedProminent)
                }
                .padding([.leading, .trailing], 16.0)
            }
            .padding([.top, .bottom], 8.0)
            .listRowInsets(EdgeInsets())
            if progressText == "" {
                ForEach(comments, id: \.id) { comment in
                    CommentItemRow(comment: comment)
                }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text(progressText)
                }
            }
        }
        .listStyle(.plain)
        .task {
            if state == .initialized {
                state = .loadingInitialData
                progressText = "コメントを読み込み中…"
                await refreshComments()
                progressText = ""
                state = .readyForInteraction
            }
        }
        .refreshable {
            await refreshComments(useCache: false)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if settings.titleLanguage == 0 || settings.commentLanguage == 0 {
                    Image("TranslateBanner")
                }
            }
        }
        .sheet(isPresented: $isSafariViewControllerPresenting) {
            if settings.linkLanguage == 0 {
                SafariView(url: URL(string: story.urlTranslated())!)
                    .ignoresSafeArea()
            } else {
                SafariView(url: URL(string: story.item.url!)!)
                    .ignoresSafeArea()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("スレッド")
    }

    func refreshComments(useCache: Bool = true) async {
        comments = await stories.fetchComments(ids: story.item.kids ?? [],
                                               translator: translator) {
            // TODO: Report progress to view
        }
        stories.saveCache()
    }
}
