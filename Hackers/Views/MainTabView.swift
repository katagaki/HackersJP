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
                    Text("記事")
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
            LicensesView()
                .tabItem {
                    Text("著者権")
                    Image(systemName: "books.vertical.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
