//
//  HNStoryType.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import Foundation

enum HNStoryType {
    case top
    case show
    case job
    
    func getConfig() -> HNStoryConfiguration {
        switch self {
        case .top:
            return HNStoryConfiguration(jsonName: "topstories", 
                                        viewTitle: "記事")
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
