//
//  StoryItemRow.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import FaviconFinder
import SwiftUI

struct StoryItemRow: View {

    @EnvironmentObject var miniCache: CacheManager
    @EnvironmentObject var settings: SettingsManager

    @State var story: HNItemLocalizable
    @State var imageState: ViewState = .initialized

    var body: some View {
        if story.item.id != -1 {
            VStack(alignment: .leading, spacing: 2.0) {
                Text((settings.titleLanguage == 0 ?
                      story.titleLocalized : story.item.title) ?? "")
                    .font(.body)
                    .layoutPriority(1)
                HStack(alignment: .center, spacing: 4.0) {
                    if let hostname = story.hostname() {
                        if let favicon = story.favicon() {
                            Image(uiImage: favicon)
                                .resizable()
                                .frame(width: 12, height: 12)
                                .fixedSize()
                                .clipShape(RoundedRectangle(cornerRadius: 2.0))
                                .transition(.opacity)
                                .task {
                                    miniCache.cache(newItem: story)
                                }
                        } else {
                            Image(systemName: "globe")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .fixedSize()
                        }
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
            .task {
                if imageState == .initialized {
                    imageState = .loadingInitialData
                    if story.faviconData == nil {
                        if let faviconData = await story.downloadFavicon() {
                            story.faviconData = faviconData
                            imageState = .initalDataLoaded
                        }
                    }
                    imageState = .readyForPresentation
                }
            }
        }
    }
}
