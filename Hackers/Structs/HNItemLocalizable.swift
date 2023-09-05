//
//  HNItemLocalizable.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/25.
//

import Foundation
import SwiftSoup
import UIKit

struct HNItemLocalizable: Identifiable, Equatable, Hashable, Codable {

    var id: Int {
        get {
            return item.id
        }
    }

    var item: HNItem

    var titleLocalized: String = ""
    var textLocalized: String = ""
    var isShowHNStory: Bool = false
    var faviconURL: String?
    var cacheDate: Date?

    static func == (lhs: HNItemLocalizable, rhs: HNItemLocalizable) -> Bool {
        lhs.id == rhs.id && lhs.faviconURL == rhs.faviconURL
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // swiftlint:disable line_length
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
    // swiftlint:enable line_length

    func hostname() -> String? {
        if let url = item.url {
            return URL(string: url)?.host
        } else {
            return nil
        }
    }

    func textDeformatted() -> String? {
        do {
            if let text = item.text {
                let doc = try SwiftSoup.parse(text.replacingOccurrences(of: "<p>", with: "\\n")
                    .replacingOccurrences(of: "<br>", with: "\\n")
                    .replacingOccurrences(of: "</br>", with: "\\n"))
                return try doc.text().replacingOccurrences(of: "\\n", with: "\n")
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return nil
    }
}
