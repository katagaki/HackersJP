//
//  StoriesView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Alamofire
import SwiftUI

struct StoriesView: View {

    @State var stories: [HNItem] = []
    @State var errorText: String = ""

    var body: some View {
        NavigationStack {
            List(stories, id: \.id, rowContent: { story in
                if story.id != -1 {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(story.title ?? "")
                            .font(.body)
                        Text(story.url ?? "")
                            .font(.caption)
                    }
                }
            })
            .task {
                do {
                    errorText = ""
                    let storyIDs = try await AF.request("\(apiEndpoint)/topstories.json",
                                                        method: .get)
                        .serializingDecodable([Int].self,
                                              decoder: JSONDecoder()).value
                    stories = await withTaskGroup(of: HNItem.self, returning: [HNItem].self, body: { group in
                        var stories: [HNItem] = []
                        for storyID in storyIDs[0..<10] {
                            group.addTask {
                                do {
                                    let storyItem = try await AF.request("\(apiEndpoint)/item/\(storyID).json",
                                                                         method: .get)
                                        .serializingDecodable(HNItem.self,
                                                              decoder: JSONDecoder()).value
                                    return storyItem
                                } catch {
                                    return HNItem(id: -1, type: "", by: "", time: 0)
                                }
                            }
                        }
                        for await result in group {
                            stories.append(result)
                        }
                        return stories
                    })
                } catch {
                    errorText = error.localizedDescription
                }
            }
            .overlay {
                if errorText != "" {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.largeTitle)
                        Text(errorText)
                    }
                } else {
                    if stories.count == 0 {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("記事")
        }
    }
}

#Preview {
    StoriesView()
}
