//
//  StoryManager+Stories.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import Alamofire
import FaviconFinder
import Foundation
import MLKitTranslate

extension StoryManager {

    // MARK: - Stories

    func fetchStories(ids: [Int],
                      translator: Translator,
                      translationService: Int = 0,
                      fetchFreshStory: Bool = false,
                      storyFetchedAction: @escaping () -> Void) async -> [HNItemLocalizable] {
        let fetchedStories = await withTaskGroup(of: HNItemLocalizable?.self,
                                      returning: [HNItemLocalizable].self, body: { group in
            var stories: [HNItemLocalizable] = []
            for id in ids {
                group.addTask(priority: .high) {
                    do {
                        return try await self.story(id: id,
                                                    translator: translator,
                                                    translationService: translationService,
                                                    fetchFreshStory: fetchFreshStory)
                    } catch {
                        #if DEBUG
                        debugPrint(error.localizedDescription)
                        #endif
                        return nil
                    }
                }
            }
            for await result in group {
                if let result = result {
                    storyFetchedAction()
                    stories.append(result)
                }
            }
            return stories
        })
        var correctlyOrderedStories = [HNItemLocalizable]()
        for id in ids {
            if let fetchedStory = fetchedStories.first(where: { $0.id == id }) {
                correctlyOrderedStories.append(fetchedStory)
            }
        }
        saveCache()
        return correctlyOrderedStories
    }

    // swiftlint:disable function_body_length
    func story(id: Int,
               translator: Translator,
               translationService: Int = 0,
               fetchFreshStory: Bool = false) async throws -> HNItemLocalizable {
        #if DEBUG
        debugPrint("[\(id)] Attempting to get story from cache...")
        #endif
        if !fetchFreshStory,
           let loadedStory = cache[id] {
            return loadedStory
        }
        #if DEBUG
        debugPrint("[\(id)] Attempting to fetch story from API...")
        #endif
        let storyItem = try await AF.request("\(apiEndpoint)/item/\(id).json",
                                             method: .get)
            .serializingDecodable(HNItem.self,
                                  decoder: JSONDecoder()).value
        #if DEBUG
        debugPrint("[\(id)] Creating localizable object...")
        #endif
        var newLocalizableItem = HNItemLocalizable(item: storyItem)

        // Determine title translation input
        let isShowHN = newLocalizableItem.item.title?.starts(with: "Show HN: ") == true
        let titleToTranslate: String? = {
            guard let title = storyItem.title else { return nil }
            return isShowHN ? title.replacingOccurrences(of: "Show HN: ", with: "") : title
        }()

        // Determine text translation input
        let textToTranslate = newLocalizableItem.textDeformatted() ?? storyItem.text ?? ""

        // Run title translation, text translation, and favicon fetch concurrently
        #if DEBUG
        debugPrint("[\(id)] Localizing title, text, and fetching favicon concurrently...")
        #endif
        async let titleTranslation: String? = {
            guard let title = titleToTranslate else { return nil }
            return try await self.translateText(title, translator: translator, translationService: translationService)
        }()

        async let textTranslation = translateText(textToTranslate,
                                                   translator: translator,
                                                   translationService: translationService)

        async let faviconURL: String? = {
            guard let url = storyItem.url else { return nil }
            do {
                let fetchedFavicon = try await FaviconFinder(
                    url: URL(string: url)!,
                    preferredType: .html,
                    preferences: [
                        .html: FaviconType.appleTouchIconPrecomposed.rawValue,
                        .ico: "favicon.ico",
                        .webApplicationManifestFile: FaviconType.launcherIcon4x.rawValue
                    ],
                    downloadImage: false,
                    logEnabled: true
                ).downloadFavicon()
                return fetchedFavicon.url.absoluteString
            } catch {
                #if DEBUG
                debugPrint(error.localizedDescription)
                #endif
                return nil
            }
        }()

        if isShowHN {
            newLocalizableItem.isShowHNStory = true
            newLocalizableItem.item.title = storyItem.title?.replacingOccurrences(of: "Show HN: ", with: "")
        }
        newLocalizableItem.titleLocalized = try await titleTranslation ?? ""
        newLocalizableItem.textLocalized = try await textTranslation
        newLocalizableItem.faviconURL = await faviconURL
        newLocalizableItem.cacheDate = Date()
        cache(newItem: newLocalizableItem)
        return newLocalizableItem
    }
    // swiftlint:enable function_body_length
}
