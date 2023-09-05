//
//  StoryItemRow.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

struct StoryItemRow: View {

    @EnvironmentObject var stories: StoryManager
    @EnvironmentObject var settings: SettingsManager

    @Binding var story: HNItemLocalizable
    @State var state: ViewState = .initialized

    var body: some View {
        if story.item.id != -1 {
            VStack(alignment: .leading, spacing: 2.0) {
                Text((settings.titleLanguage == 0 ?
                      story.titleLocalized : story.item.title) ?? "")
                    .font(.body)
                    .layoutPriority(1)
                HStack(alignment: .center, spacing: 4.0) {
                    if let hostname = story.hostname() {
                        Group {
                            if let storedFaviconURL = story.faviconURL,
                               let faviconURL = URL(string: storedFaviconURL) {
                                AsyncImage(url: faviconURL) { image in
                                    image
                                        .resizable()
                                        .clipShape(RoundedRectangle(cornerRadius: 2.0))
                                        .transition(AnyTransition.opacity.animation(.default))
                                } placeholder: {
                                    Image(systemName: "globe")
                                        .resizable()
                                }
                            } else {
                                Image(systemName: "globe")
                                    .resizable()
                            }
                        }
                        .frame(width: 12, height: 12)
                        .fixedSize()
                        Text(hostname)
                        Divider()
                    }
                    if story.isShowHNStory {
                        Text("展示")
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
        }
    }
}
