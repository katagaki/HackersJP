//
//  App.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import SwiftUI

@main
struct HackersApp: App {

    @StateObject var tabManager = TabManager()
    @StateObject var navigationManager = NavigationManager()
    @StateObject var stories = StoryManager()
    @StateObject var settings = SettingsManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(tabManager)
                .environmentObject(navigationManager)
                .environmentObject(stories)
                .environmentObject(settings)
        }
    }
}
