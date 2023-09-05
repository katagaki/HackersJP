//
//  MainTabView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Alamofire
import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var tabManager: TabManager
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var stories: StoryManager
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        TabView(selection: $tabManager.selectedTab) {
            StoriesView(type: settings.feedSort)
                .tabItem {
                    Text("フィード")
                    Image(systemName: "newspaper.fill")
                }
                .tag(TabType.feed)
            StoriesView(type: .job)
                .tabItem {
                    Text("求人")
                    Image(systemName: "info.bubble.fill")
                }
                .tag(TabType.jobs)
            StoriesView(type: .show)
                .tabItem {
                    Text("展示")
                    Image(systemName: "sparkles.rectangle.stack.fill")
                }
                .tag(TabType.show)
            MoreView()
                .tabItem {
                    Text("その他")
                    Image(systemName: "ellipsis")
                }
                .tag(TabType.more)
        }
        .task {
            tabManager.selectedTab = TabType(rawValue: settings.startupTab) ?? .feed
            stories.cleanUpCache()
        }
        .onReceive(tabManager.$selectedTab, perform: { newValue in
            if newValue == tabManager.previouslySelectedTab {
                navigationManager.popToRoot(for: newValue)
            }
            tabManager.previouslySelectedTab = newValue
        })
    }
}
