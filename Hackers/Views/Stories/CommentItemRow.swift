//
//  CommentItemRow.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/25.
//

import SwiftUI

struct CommentItemRow: View {

    @EnvironmentObject var settings: SettingsManager

    @State var comment: HNItemLocalizable
    var depth: Int = 0
    var isCollapsed: Bool = false
    var hasChildren: Bool = false
    var onTap: (() -> Void)?

    private let depthColors: [Color] = [
        .blue, .green, .orange, .purple, .red, .teal, .indigo, .mint
    ]

    var body: some View {
        HStack(spacing: 0) {
            if depth > 0 {
                ForEach(0..<depth, id: \.self) { level in
                    Rectangle()
                        .fill(depthColors[level % depthColors.count])
                        .frame(width: 2)
                        .padding(.trailing, 6)
                }
            }
            VStack(alignment: .leading, spacing: 2.0) {
                HStack(alignment: .center, spacing: 4.0) {
                    Text(comment.item.by)
                    Divider()
                    Text(Date(timeIntervalSince1970: TimeInterval(comment.item.time)),
                         style: .relative)
                    if hasChildren {
                        Spacer()
                        Image(systemName: isCollapsed ? "chevron.forward" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                if !isCollapsed {
                    Text((settings.commentLanguage == 0 ?
                          comment.textLocalized : comment.textDeformatted() ??
                          comment.item.text) ?? "")
                    .font(.subheadline)
                    .layoutPriority(1)
                    .textSelection(.enabled)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
}
