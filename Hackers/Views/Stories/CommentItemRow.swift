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

    var body: some View {
        VStack(alignment: .leading, spacing: 2.0) {
            HStack(alignment: .center, spacing: 4.0) {
                Text(comment.item.by)
                Divider()
                Text(Date(timeIntervalSince1970: TimeInterval(comment.item.time)), 
                     style: .relative)
            }
            .font(.caption)
            .lineLimit(1)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            Text((settings.commentLanguage == 0 ?
                  comment.textLocalized : comment.textDeformatted() ??
                  comment.item.text) ?? "")
            .font(.subheadline)
            .layoutPriority(1)
            .textSelection(.enabled)
        }
    }
}
