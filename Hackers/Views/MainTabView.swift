//
//  MainTabView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Alamofire
import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var settings: SettingsManager

    @State var defaultTab: Int = 0

    var body: some View {
        TabView(selection: $defaultTab) {
            StoriesView(type: settings.feedSort)
                .tabItem {
                    Text("フィード")
                    Image(systemName: "newspaper.fill")
                }
                .tag(0)
            StoriesView(type: .job)
                .tabItem {
                    Text("求人")
                    Image(systemName: "person.bubble.fill")
                }
                .tag(1)
            StoriesView(type: .show)
                .tabItem {
                    Text("展示")
                    Image(systemName: "sparkles.rectangle.stack.fill")
                }
                .tag(2)
            MoreView()
                .tabItem {
                    Text("その他")
                    Image(systemName: "ellipsis")
                }
        }
        .task {
            defaultTab = settings.startupTab
        }
    }
}
