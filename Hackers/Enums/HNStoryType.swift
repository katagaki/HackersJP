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
                                        viewTitle: NSLocalizedString("フィード", comment: ""))
        case .new:
            return HNStoryConfiguration(jsonName: "newstories",
                                        viewTitle: NSLocalizedString("フィード", comment: ""))
        case .best:
            return HNStoryConfiguration(jsonName: "beststories",
                                        viewTitle: NSLocalizedString("フィード", comment: ""))
        case .show:
            return HNStoryConfiguration(jsonName: "showstories",
                                        viewTitle: NSLocalizedString("展示", comment: ""))
        case .job:
            return HNStoryConfiguration(jsonName: "jobstories",
                                        viewTitle: NSLocalizedString("求人", comment: ""))
        }
    }
}

struct HNStoryConfiguration {
    var jsonName: String
    var viewTitle: String
}
