//
//  HackersBackground.swift
//  Hackers
//
//  Created by シンジャスティン on 2026/05/09.
//

import SwiftUI

struct HackersBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [
                        Color("BackgroundGradientTop"),
                        Color("BackgroundGradientBottom")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func hackersBackground() -> some View {
        modifier(HackersBackground())
    }
}
