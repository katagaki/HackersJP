//
//  StoryItemView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

struct StoryItemView: View {

    @State var story: HNItemLocalizable
    @Binding var isTranslateEnabled: Bool

    var body: some View {
        if story.item.id != -1 {
            if let url = story.item.url {
                Link(destination: URL(string: url)!) {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text((isTranslateEnabled ?
                              story.titleLocalized : story.item.title) ?? "")
                            .font(.body)
                        Text(hostname(of: url))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text((isTranslateEnabled ?
                      story.titleLocalized : story.item.title) ?? "")
                    .font(.body)
            }
        }
    }

    func hostname(of string: String) -> String {
        return URL(string: string)?.host ?? ""
    }
}
