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
    
    func setRequiresCachingToFalseForAll() {
        for index in feed.indices {
            feed[index].requiresCaching = false
        }
        for index in jobs.indices {
            jobs[index].requiresCaching = false
        }
        for index in showStories.indices {
            showStories[index].requiresCaching = false
        }
    }
}
