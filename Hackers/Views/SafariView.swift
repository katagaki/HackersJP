//
//  SafariView.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/23.
//

import SafariServices
import SwiftUI
import UIKit

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.barCollapsingEnabled = false

        let safariViewController = SFSafariViewController(
            url: url,
            configuration: configuration)
        safariViewController.dismissButtonStyle = .close
        safariViewController.preferredControlTintColor = UIColor(named: "AccentColor")
        safariViewController.hidesBottomBarWhenPushed = false

        return safariViewController
    }
    
    func updateUIViewController(_ safariViewController: SFSafariViewController, context: Context) {

    }
}
