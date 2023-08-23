//
//  StoryItemView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import FaviconFinder
import SwiftUI

struct StoryItemView: View {

    @State var story: HNItemLocalizable
    @State var favicon: UIImage? = nil
    @State var isFirstFaviconFetchCompleted: Bool = false
    @Binding var isTranslateEnabled: Bool

    var body: some View {
        if story.item.id != -1 {
            if let url = story.item.url {
                VStack(alignment: .leading, spacing: 2.0) {
                    Text((isTranslateEnabled ?
                          story.titleLocalized : story.item.title) ?? "")
                        .font(.body)
                    HStack(alignment: .center, spacing: 4.0) {
                        if let favicon = favicon {
                            Image(uiImage: favicon)
                                .resizable()
                                .frame(width: 12, height: 12)
                                .fixedSize()
                                .clipShape(RoundedRectangle(cornerRadius: 2.0))
                        } else {
                            Image(systemName: "globe")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .fixedSize()
                                .task {
                                    if !isFirstFaviconFetchCompleted {
                                        do {
                                            let downloadedFavicon = try await FaviconFinder(
                                                url: URL(string: url)!,
                                                preferredType: .html,
                                                preferences: [
                                                    .html: FaviconType.appleTouchIcon.rawValue,
                                                    .ico: "favicon.ico",
                                                    .webApplicationManifestFile: FaviconType.launcherIcon4x.rawValue
                                                ]
                                            ).downloadFavicon()
                                            favicon = downloadedFavicon.image
                                        } catch {
                                            debugPrint("Favicon not found.")
                                        }
                                        isFirstFaviconFetchCompleted = true
                                    }
                                }
                        }
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
