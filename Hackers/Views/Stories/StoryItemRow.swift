//
//  StoryItemRow.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import FaviconFinder
import SwiftUI

struct StoryItemRow: View {

    @EnvironmentObject var stories: StoryManager
    @EnvironmentObject var miniCache: CacheManager
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
            .task {
                if state == .initialized {
                    state = .loadingInitialData
                    if story.faviconURL == nil && !story.faviconWasNotFoundOnLastFetch {
                        debugPrint("[\(story.item.id)] Getting favicon from Internet...")
                        if let fetchedFaviconURL = await getFaviconURL() {
                            story.faviconURL = fetchedFaviconURL
                            stories.storiesPendingCache.append(story)
                        } else {
                            story.faviconWasNotFoundOnLastFetch = true
                        }
                    }
                    state = .readyForPresentation
                }
            }
        }
    }

    func getFaviconURL() async -> String? {
        if let url = story.item.url {
            do {
                let fetchedFavicon = try await FaviconFinder(
                    url: URL(string: url)!,
                    preferredType: .html,
                    preferences: [
                        .html: FaviconType.appleTouchIconPrecomposed.rawValue,
                        .ico: "favicon.ico",
                        .webApplicationManifestFile: FaviconType.launcherIcon4x.rawValue
                    ],
                    downloadImage: false,
                    logEnabled: true
                ).downloadFavicon()
                return fetchedFavicon.url.absoluteString
            } catch {
                debugPrint(error.localizedDescription)
                return nil
            }
        }
        return nil
    }

}
