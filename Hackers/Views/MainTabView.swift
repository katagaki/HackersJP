//
//  MainTabView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Alamofire
import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {
            StoriesView(type: .top)
                .tabItem {
                    Text("フィード")
                    Image(systemName: "newspaper.fill")
                }
            StoriesView(type: .job)
                .tabItem {
                    Text("求人")
                    Image(systemName: "person.bubble.fill")
                }
            StoriesView(type: .show)
                .tabItem {
                    Text("展示")
                    Image(systemName: "sparkles.rectangle.stack.fill")
                }
            MoreView()
                .tabItem {
                    Text("その他")
                    Image(systemName: "ellipsis")
                }
        }
    }
}
