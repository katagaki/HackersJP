//
//  Overlay.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import SwiftUI

struct Overlay: View {

    @Binding var overlayMode: OverlayMode
    @Binding var overlayText: String
    @Binding var overlayCurrent: Int
    @Binding var overlayTotal: Int

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            switch overlayMode {
            case .progress:
                ProgressView(value: Double(overlayCurrent),
                             total: Double(overlayTotal))
                .progressViewStyle(.linear)
                .frame(width: 200.0)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.largeTitle)
            }
            Text(overlayText)
                .font(.body)
            if overlayMode == .progress {
                Text("\(overlayCurrent) / \(overlayTotal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8.0))
        .padding()
    }
}
