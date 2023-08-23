//
//  MoreView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Link(destination: URL(string: "https://twitter.com/katagaki_")!) {
                        HStack {
                            ListRow(image: "ListIcon.Twitter",
                                    title: "ツイート",
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
                                title: "著者権",
                                includeSpacer: true)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("その他")
        }
    }
}

#Preview {
    MoreView()
}
