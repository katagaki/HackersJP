//
//  StoryManager.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import Foundation

class StoryManager: ObservableObject {
    @Published var feed: [HNItemLocalizable] = []
    @Published var jobs: [HNItemLocalizable] = []
    @Published var showStories: [HNItemLocalizable] = []
    var storiesPendingCache: [HNItemLocalizable] = []
}
