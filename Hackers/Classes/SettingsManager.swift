//
//  SettingsManager.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/25.
//

import Foundation

class SettingsManager: ObservableObject {

    let defaults = UserDefaults.standard
    let versionNumber: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "Dev"
    let buildNumber: String = Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? "Dev"

    @Published var startupTab: Int = 0
    @Published var feedSort: HNStoryType = .top
    @Published var pageStoryCount: Int = 10
    @Published var titleLanguage: Int = 0
    @Published var linkLanguage: Int = 0

    init() {
        // Detect if version changed
        if defaults.value(forKey: "CurrentVersion") != nil,
           let previouslyDetectedVersion = defaults.string(forKey: "CurrentVersion"),
           previouslyDetectedVersion != "\(versionNumber).\(buildNumber)" {
        }
        defaults.setValue("\(versionNumber).\(buildNumber)", forKey: "CurrentVersion")

        // Set default settings
        if defaults.value(forKey: "StartupTab") == nil {
            defaults.set(0, forKey: "StartupTab")
        }
        if defaults.value(forKey: "FeedSort") == nil {
            defaults.setValue(0, forKey: "FeedSort")
        }
        if defaults.value(forKey: "PageStoryCount") == nil {
            defaults.setValue(20, forKey: "PageStoryCount")
        }
        if defaults.value(forKey: "TitleLanguage") == nil {
            defaults.setValue(0, forKey: "TitleLanguage")
        }
        if defaults.value(forKey: "LinkLanguage") == nil {
            defaults.setValue(0, forKey: "LinkLanguage")
        }

        // Load configuration into global variables
        startupTab = defaults.integer(forKey: "StartupTab")
        feedSort = HNStoryType.init(
            rawValue: defaults.integer(forKey: "FeedSort")) ?? .top
        pageStoryCount = defaults.integer(forKey: "PageStoryCount")
        titleLanguage = defaults.integer(forKey: "TitleLanguage")
        linkLanguage = defaults.integer(forKey: "LinkLanguage")
    }

    func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func setStartupTab(_ newValue: Int) {
        defaults.set(newValue, forKey: "StartupTab")
        startupTab = newValue
    }

    func setFeedSort(_ newValue: HNStoryType) {
        defaults.set(newValue.rawValue, forKey: "FeedSort")
        feedSort = newValue
    }

    func setPageStoryCount(_ newValue: Int) {
        defaults.set(newValue, forKey: "PageStoryCount")
        pageStoryCount = newValue
    }

    func setTitleLanguage(_ newValue: Int) {
        defaults.set(newValue, forKey: "TitleLanguage")
        titleLanguage = newValue
    }

    func setLinkLanguage(_ newValue: Int) {
        defaults.set(newValue, forKey: "LinkLanguage")
        linkLanguage = newValue
    }

}
