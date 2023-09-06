//
//  MoreView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

struct MoreView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        NavigationStack(path: $navigationManager.moreTabPath) {
            List {
                Section {
                    Picker(selection: $settings.startupTab) {
                        Text("フィード")
                            .tag(0)
                        Text("求人")
                            .tag(1)
                        Text("展示")
                            .tag(2)
                    } label: {
                        ListRow(image: "ListIcon.Startup",
                                title: "デフォルトタブ")
                    }
                    NavigationLink(value: ViewPath.moreCache) {
                        ListRow(image: "ListIcon.Cache",
                                title: "キャッシュ管理")
                    }
                } header: {
                    ListSectionHeader(text: "一般")
                        .font(.body)
                }
                Section {
                    Picker(selection: $settings.feedSort) {
                        Text("トップ")
                            .tag(HNStoryType.top)
                        Text("新しい順")
                            .tag(HNStoryType.new)
                        Text("ベスト")
                            .tag(HNStoryType.best)
                    } label: {
                        ListRow(image: "ListIcon.Sort",
                                title: "並べ替え")
                    }
                    Picker(selection: $settings.pageStoryCount) {
                        Text("10件")
                            .tag(10)
                        Text("20件")
                            .tag(20)
                        Text("30件")
                            .tag(30)
                    } label: {
                        ListRow(image: "ListIcon.PageStoryCount",
                                title: "ページの記事数")
                    }
                } header: {
                    ListSectionHeader(text: "フィード")
                        .font(.body)
                }
                Section {
                    Picker(selection: $settings.titleLanguage) {
                        Text("日本語")
                            .tag(0)
                        Text("英語")
                            .tag(1)
                    } label: {
                        ListRow(image: "ListIcon.Language.Title",
                                title: "タイトルおよび内容",
                                subtitle: settings.titleLanguage == 0 ? "オフラインで翻訳されます。" : "英語の原文で表示されます。")
                    }
                    Picker(selection: $settings.commentLanguage) {
                        Text("日本語")
                            .tag(0)
                        Text("英語")
                            .tag(1)
                    } label: {
                        ListRow(image: "ListIcon.Language.Comment",
                                title: "コメント",
                                subtitle: settings.commentLanguage == 0 ? "オフラインで翻訳されます。" : "英語の原文で表示されます。")
                    }
                    Picker(selection: $settings.linkLanguage) {
                        Text("日本語")
                            .tag(0)
                        Text("英語")
                            .tag(1)
                    } label: {
                        ListRow(image: "ListIcon.Language.Article",
                                title: "記事",
                                subtitle: settings.linkLanguage == 0 ? "翻訳されたページを開きます。" : "元の記事を開きます。")
                    }
                } header: {
                    ListSectionHeader(text: "言語")
                        .font(.body)
                }
                Section {
                    Link(destination: URL(string: "https://x.com/katagaki_")!) {
                        HStack {
                            ListRow(image: "ListIcon.Twitter",
                                    title: "Xでポスト",
                                    subtitle: "@katagaki_",
                                    includeSpacer: true)
                            Image(systemName: "safari")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                    Link(destination: URL(string: "mailto:ktgk.public@icloud.com")!) {
                        HStack {
                            ListRow(image: "ListIcon.Email",
                                    title: "メールを送信",
                                    subtitle: "ktgk.public@icloud.com",
                                    includeSpacer: true)
                            Image(systemName: "arrow.up.forward.app")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                    Link(destination: URL(string: "https://github.com/katagaki/HackersJP")!) {
                        HStack {
                            ListRow(image: "ListIcon.GitHub",
                                    title: "ソースコードを閲覧",
                                    subtitle: "katagaki/HackersJP",
                                    includeSpacer: true)
                            Image(systemName: "safari")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    ListSectionHeader(text: "サポート")
                        .font(.body)
                }
                Section {
                    NavigationLink(value: ViewPath.moreAttributions) {
                        ListRow(image: "ListIcon.Attributions",
                                title: "著者権表記")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .moreCache: CacheView()
                case .moreAttributions: LicensesView()
                default: Color.clear
                }
            })
            .onChange(of: settings.startupTab, perform: { value in
                settings.setStartupTab(value)
            })
            .onChange(of: settings.feedSort, perform: { value in
                settings.setFeedSort(value)
            })
            .onChange(of: settings.pageStoryCount, perform: { value in
                settings.setPageStoryCount(value)
            })
            .onChange(of: settings.titleLanguage, perform: { value in
                settings.setTitleLanguage(value)
            })
            .onChange(of: settings.commentLanguage, perform: { value in
                settings.setCommentLanguage(value)
            })
            .onChange(of: settings.linkLanguage, perform: { value in
                settings.setLinkLanguage(value)
            })
            .navigationTitle("その他")
        }
    }
}
