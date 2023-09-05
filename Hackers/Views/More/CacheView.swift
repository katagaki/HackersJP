//
//  CacheView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/25.
//

import SwiftUI

struct CacheView: View {

    @EnvironmentObject var stories: StoryManager

    var body: some View {
        List {
            Section {
                HStack(alignment: .center, spacing: 8) {
                    Text("使用中")
                        .font(.body)
                    Spacer()
                    Text(calculateUsedSpaceInMB())
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Button {
                    stories.clearCache()
                } label: {
                    Text("キャッシュをクリア")
                        .font(.body)
                        .foregroundStyle(.red)
                }
            } header: {
                ListSectionHeader(text: "ストレージ")
                    .font(.body)
            }
            Section {
                ForEach(Array(stories.cache.values.sorted(by: { lhs, rhs in
                    lhs.cacheDate ?? Date() < rhs.cacheDate ?? Date()
                }))) { cachedItem in
                    HStack(alignment: .center, spacing: 8) {
                        Text(String(cachedItem.item.id))
                            .font(.body)
                        Spacer()
                        if let cacheDate = cachedItem.cacheDate {
                            Text(cacheDate, style: .relative)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                ListSectionHeader(text: "コンテンツ")
                    .font(.body)
            }
        }
        .navigationTitle("キャッシュ管理")
    }

    func calculateUsedSpaceInMB() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(stories.usedCacheSpace()))
    }
}
