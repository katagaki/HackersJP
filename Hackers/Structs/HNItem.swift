//
//  HNItem.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/22.
//

import Foundation

let apiEndpoint = "https://hacker-news.firebaseio.com/v0"

struct HNItemLocalizable: Identifiable {

    var id: Int {
        get {
            return item.id
        }
    }
    var titleLocalized: String
    var item: HNItem

    func urlTranslated() -> String {
        if let itemURL = item.url,
           let url = URL(string: itemURL) {
            let host = url.host()!
            let path = url.path()
            if path == "" {
                return "https://\(host.replacingOccurrences(of: ".", with: "-")).translate.goog/?_x_tr_sl=auto&_x_tr_tl=ja&_x_tr_hl=ja"
            } else {
                return "https://\(host.replacingOccurrences(of: ".", with: "-")).translate.goog\(path)?_x_tr_sl=auto&_x_tr_tl=ja&_x_tr_hl=ja"
            }
        }
        return ""
    }
}

struct HNItem: Decodable {
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
