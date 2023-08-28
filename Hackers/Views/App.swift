//
//  App.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import SwiftUI

@main
struct HackersApp: App {
    
    @StateObject var miniCache = CacheManager()
    @StateObject var settings = SettingsManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(miniCache)
                .environmentObject(settings)
        }
    }
}