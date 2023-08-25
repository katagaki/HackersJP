//
//  HNItemLocalizable.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/25.
//

import FaviconFinder
import Foundation
import SwiftSoup
import UIKit

struct HNItemLocalizable: Identifiable, Codable {

    var id: Int {
        get {
            return item.id
        }
    }

    var item: HNItem

    var titleLocalized: String = ""
    var textLocalized: String = ""
    var faviconData: Data? = nil
    var cacheDate: Date? = nil

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

    func hostname() -> String? {
        if let url = item.url {
            return URL(string: url)?.host
        } else {
            return nil
        }
    }
    
    func favicon() -> UIImage? {
        if let favicon = faviconData {
            return UIImage(data: favicon) ?? nil
        }
        return nil
    }

    mutating func downloadFavicon() async {
        if let url = item.url {
            do {
                let downloadedFavicon = try await FaviconFinder(
                    url: URL(string: url)!,
                    preferredType: .html,
                    preferences: [
                        .html: FaviconType.appleTouchIconPrecomposed.rawValue,
                        .ico: "favicon.ico",
                        .webApplicationManifestFile: FaviconType.launcherIcon4x.rawValue
                    ]
                ).downloadFavicon()
                faviconData = downloadedFavicon.image.pngData()
            } catch {
                debugPrint("Favicon not found.")
                faviconData = nil
            }
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
