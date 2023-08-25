//
//  HNItem.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Foundation

struct HNItem: Codable {
    var id: Int
    var deleted: Bool?
    var type: String
    var by: String
    var time: Int64
    var text: String?
    var dead: Bool?
    var parent: Int?
    var poll: Int?
    var kids: [Int]?
    var url: String?
    var score: Int?
    var title: String?
    var parts: [Int]?
    var descendants: Int?
}
