//
//  MoreView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

struct MoreView: View {

    @State var defaultLanguage: Int = 0
    @State var defaultSort: Int = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(selection: $defaultLanguage) {
                        Text("日本語")
                            .tag(0)
                        Text("英語（原文）")
                            .tag(1)
                    } label: {
                        ListRow(image: "ListIcon.Language",
                                title: "言語")
                    }
                    Picker(selection: $defaultSort) {
                        Text("トップ")
                            .tag(0)
                        Text("新しい順")
                            .tag(1)
                        Text("ベスト")
                            .tag(2)
                    } label: {
                        ListRow(image: "ListIcon.Sort",
                                title: "フィードの並べ替え")
                    }
                } header: {
                    ListSectionHeader(text: "一般")
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
                    NavigationLink {
                        LicensesView()
                    } label: {
                        ListRow(image: "ListIcon.Attributions",
                                title: "著者権表記",
                                includeSpacer: true)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("その他")
        }
    }
}
