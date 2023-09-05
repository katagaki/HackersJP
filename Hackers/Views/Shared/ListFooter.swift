//
//  ListFooter.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import SwiftUI

struct ListFooter: View {

    @Binding var footerMode: FooterDisplayMode
    @Binding var footerText: String
    @Binding var footerCurrent: Int
    @Binding var footerTotal: Int

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            switch footerMode {
            case .progress:
                ProgressView(value: Double(footerCurrent),
                             total: Double(footerTotal))
                .progressViewStyle(.linear)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.largeTitle)
            }
            Text(footerText)
                .font(.body)
            if footerMode == .progress {
                Text("\(footerCurrent) / \(footerTotal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
