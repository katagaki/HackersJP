//
//  TabManager.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/30.
//

import Foundation

class TabManager: ObservableObject {
    @Published var selectedTab: TabType = .feed
    @Published var previouslySelectedTab: TabType = .feed
}
