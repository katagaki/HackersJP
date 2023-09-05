//
//  HNStoryType.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import Foundation

enum HNStoryType: Int, Codable {
    case top = 0
    case new = 1
    case best = 2
    case show = 3
    case job = 4

    func getConfig() -> HNStoryConfiguration {
        switch self {
        case .top:
            return HNStoryConfiguration(jsonName: "topstories",
                                        viewTitle: "フィード")
        case .new:
            return HNStoryConfiguration(jsonName: "newstories",
                                        viewTitle: "フィード")
        case .best:
            return HNStoryConfiguration(jsonName: "beststories",
                                        viewTitle: "フィード")
        case .show:
            return HNStoryConfiguration(jsonName: "showstories",
                                        viewTitle: "展示")
        case .job:
            return HNStoryConfiguration(jsonName: "jobstories",
                                        viewTitle: "求人")
        }
    }
}

struct HNStoryConfiguration {
    var jsonName: String
    var viewTitle: String
}
