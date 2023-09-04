//
//  NavigationManager.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/30.
//

import Foundation

class NavigationManager: ObservableObject {

    @Published var feedTabPath: [HNItemLocalizable] = []
    @Published var jobsTabPath: [HNItemLocalizable] = []
    @Published var showTabPath: [HNItemLocalizable] = []
    @Published var moreTabPath: [ViewPath] = []

    func popToRoot(for tab: TabType) {
        switch tab {
        case .feed:
            feedTabPath.removeAll()
        case .jobs:
            jobsTabPath.removeAll()
        case .show:
            showTabPath.removeAll()
        case .more:
            moreTabPath.removeAll()
        }
    }

    // swiftlint:disable force_cast
    func push(_ viewPath: AnyObject, for tab: TabType) {
        switch tab {
        case .feed:
            feedTabPath.append(viewPath as! HNItemLocalizable)
        case .jobs:
            jobsTabPath.append(viewPath as! HNItemLocalizable)
        case .show:
            showTabPath.append(viewPath as! HNItemLocalizable)
        case .more:
            moreTabPath.append(viewPath as! ViewPath)
        }
    }
    // swiftlint:enable force_cast

    func pop(for tab: TabType) {
        switch tab {
        case .feed:
            if !feedTabPath.isEmpty {
                feedTabPath.removeLast()
            }
        case .jobs:
            if !jobsTabPath.isEmpty {
                jobsTabPath.removeLast()
            }
        case .show:
            if !showTabPath.isEmpty {
                showTabPath.removeLast()
            }
        case .more:
            if !moreTabPath.isEmpty {
                moreTabPath.removeLast()
            }
        }
    }
}
