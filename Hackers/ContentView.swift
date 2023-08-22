//
//  ContentView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Alamofire
import SwiftUI

struct ContentView: View {

    @State var storyIDs: [Int] = []

    var body: some View {
        TabView {
            NavigationStack {
                List(storyIDs, id: \.description, rowContent: { storyID in
                    Text(storyID.description)
                })
                .task {
                    do {
                        storyIDs = try await AF.request("https://hacker-news.firebaseio.com/v0/topstories.json",
                                                        method: .get)
                        .serializingDecodable([Int].self,
                                              decoder: JSONDecoder()).value
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                }
            }
            .tabItem {
                Text("記事")
                Image(systemName: "newspaper.fill")
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
    ContentView()
}
