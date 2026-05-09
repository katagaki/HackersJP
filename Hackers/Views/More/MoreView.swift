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
                generalSection
                feedSection
                languageSection
                aboutSection
            }
            .hackersBackground()
            .navigationDestination(for: ViewPath.self, destination: { viewPath in
                switch viewPath {
                case .moreCache: CacheView()
                case .moreAttributions: MoreLicensesView()
                default: Color.clear
                }
            })
            .onChange(of: settings.startupTab) { _, newValue in
                settings.setStartupTab(newValue)
            }
            .onChange(of: settings.feedSort) { _, newValue in
                settings.setFeedSort(newValue)
            }
            .onChange(of: settings.pageStoryCount) { _, newValue in
                settings.setPageStoryCount(newValue)
            }
            .onChange(of: settings.titleLanguage) { _, newValue in
                settings.setTitleLanguage(newValue)
            }
            .onChange(of: settings.commentLanguage) { _, newValue in
                settings.setCommentLanguage(newValue)
            }
            .onChange(of: settings.linkLanguage) { _, newValue in
                settings.setLinkLanguage(newValue)
            }
            .onChange(of: settings.translationService) { _, newValue in
                settings.setTranslationService(newValue)
            }
            .navigationTitle("ViewTitle.More")
        }
    }

    @ViewBuilder
    private var generalSection: some View {
        Section {
            Picker("デフォルトタブ", selection: $settings.startupTab) {
                Text("フィード").tag(0)
                Text("求人").tag(1)
                Text("展示").tag(2)
            }
            NavigationLink("キャッシュ管理", value: ViewPath.moreCache)
        } header: {
            Text("一般")
        }
    }

    @ViewBuilder
    private var feedSection: some View {
        Section {
            Picker("並べ替え", selection: $settings.feedSort) {
                Text("トップ").tag(HNStoryType.top)
                Text("新しい順").tag(HNStoryType.new)
                Text("ベスト").tag(HNStoryType.best)
            }
            Picker("ページの記事数", selection: $settings.pageStoryCount) {
                Text("10件").tag(10)
                Text("20件").tag(20)
                Text("30件").tag(30)
            }
        } header: {
            Text("フィード")
        }
    }

    @ViewBuilder
    private var languageSection: some View {
        Section {
            Picker("翻訳サービス", selection: $settings.translationService) {
                Text("Google翻訳").tag(0)
                Text("Apple翻訳").tag(1)
            }
            Picker("タイトルおよび内容", selection: $settings.titleLanguage) {
                Text("日本語").tag(0)
                Text("英語").tag(1)
            }
            Picker("コメント", selection: $settings.commentLanguage) {
                Text("日本語").tag(0)
                Text("英語").tag(1)
            }
            Picker("記事", selection: $settings.linkLanguage) {
                Text("日本語").tag(0)
                Text("英語").tag(1)
            }
        } header: {
            Text("言語")
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://github.com/katagaki/HackersJP")!) {
                HStack {
                    Text(String(localized: "More.GitHub"))
                    Spacer()
                    Text("katagaki/HackersJP")
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.primary)
            NavigationLink("More.Attributions", value: ViewPath.moreAttributions)
        }
    }
}
