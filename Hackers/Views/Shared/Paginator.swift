//
//  Paginator.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import SwiftUI

struct Paginator: View {

    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var previousAction: () -> Void
    var nextAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            Button {
                previousAction()
            } label: {
                Image(systemName: "arrowtriangle.left.fill")
            }
            .padding(.leading)
            .disabled(currentPage == 0)
            Spacer()
            Text("ページ \(currentPage + 1) / \(totalPages)")
                .padding()
            Spacer()
            Button {
                nextAction()
            } label: {
                Image(systemName: "arrowtriangle.right.fill")
            }
            .padding(.trailing)
            .disabled(currentPage + 1 >= totalPages)
        }
    }
}
