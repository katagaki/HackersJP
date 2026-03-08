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
    @State var comments: [FlatComment] = []
    @State var collapsedCommentIDs: Set<Int> = []
    @State var footerMode: FooterDisplayMode = .progress
    @State var footerCurrent: Int = 0
    @State var footerTotal: Int = 0
    @State var isSafariViewControllerPresenting: Bool = false

    var visibleComments: [FlatComment] {
        var result = [FlatComment]()
        var skipUntilDepth: Int?

        for comment in comments {
            if let skipDepth = skipUntilDepth {
                if comment.depth <= skipDepth {
                    skipUntilDepth = nil
                } else {
                    continue
                }
            }
            result.append(comment)
            if collapsedCommentIDs.contains(comment.id) {
                skipUntilDepth = comment.depth
            }
        }
        return result
    }

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
            if state == .readyForInteraction {
                ForEach(visibleComments) { flatComment in
                    let hasChildren = flatComment.comment.item.kids?.isEmpty == false
                    CommentItemRow(
                        comment: flatComment.comment,
                        depth: flatComment.depth,
                        isCollapsed: collapsedCommentIDs.contains(flatComment.id),
                        hasChildren: hasChildren,
                        onTap: hasChildren ? {
                            withAnimation {
                                if collapsedCommentIDs.contains(flatComment.id) {
                                    collapsedCommentIDs.remove(flatComment.id)
                                } else {
                                    collapsedCommentIDs.insert(flatComment.id)
                                }
                            }
                        } : nil
                    )
                }
            } else {
                ListFooter(footerMode: $footerMode,
                           footerText: .constant(NSLocalizedString("コメントを読み込み中…", comment: "")),
                           footerCurrent: $footerCurrent,
                           footerTotal: $footerTotal)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .task {
            if state == .initialized {
                state = .loadingInitialData
                await refreshComments()
                state = .readyForInteraction
            }
        }
        .refreshable {
            await refreshComments(useCache: false)
        }
        .toolbar {
            if #available(iOS 26.0, *) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if settings.titleLanguage == 0 || settings.commentLanguage == 0 {
                        Image("TranslateBanner")
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if settings.titleLanguage == 0 || settings.commentLanguage == 0 {
                        Image("TranslateBanner")
                    }
                }
            }
        }
        .sheet(isPresented: $isSafariViewControllerPresenting) {
            if settings.linkLanguage == 0 && settings.translationService == 0 {
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
        if let commentItems = story.item.kids {
            footerTotal = story.item.descendants ?? commentItems.count
            comments = await stories.fetchCommentTree(
                ids: commentItems,
                translator: translator,
                translationService: settings.translationService,
                fetchFreshComment: !useCache,
                commentFetchedAction: {
                    footerCurrent += 1
                })
        }
    }
}
