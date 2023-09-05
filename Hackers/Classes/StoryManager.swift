//
//  StoryManager.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import Alamofire
import FaviconFinder
import Foundation
import MLKitTranslate

class StoryManager: ObservableObject {

    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    var cache: [Int: HNItemLocalizable] = [:]
    @Published var cacheInMemory: Data = Data()

    init() {
        if defaults.value(forKey: "MiniCache") == nil {
            do {
                let encoded = try encoder.encode([Int: HNItemLocalizable]())
                defaults.set(encoded, forKey: "MiniCache")
            } catch {
                debugPrint(error.localizedDescription)
            }
        }

        do {
            if let data = defaults.data(forKey: "MiniCache") {
                cache = try decoder.decode([Int: HNItemLocalizable].self, from: data)
                cacheInMemory = data
                debugPrint("\(cache.count) item(s) loaded from cache.")
            }
        } catch {
            debugPrint(error.localizedDescription)
            defaults.set(nil, forKey: "MiniCache")
        }
    }

    func fetchStories(ids: [Int],
                      translator: Translator,
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
                                                    fetchFreshStory: fetchFreshStory)
                    } catch {
                        debugPrint(error.localizedDescription)
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
               fetchFreshStory: Bool = false) async throws -> HNItemLocalizable {
        debugPrint("[\(id)] Attempting to get story from cache...")
        if !fetchFreshStory,
           let loadedStory = cache[id] {
            return loadedStory
        }
        debugPrint("[\(id)] Attempting to fetch story from API...")
        let storyItem = try await AF.request("\(apiEndpoint)/item/\(id).json",
                                             method: .get)
            .serializingDecodable(HNItem.self,
                                  decoder: JSONDecoder()).value
        debugPrint("[\(id)] Creating localizable object...")
        var newLocalizableItem = HNItemLocalizable(item: storyItem)
        debugPrint("[\(id)] Localizing title...")
        if let title = newLocalizableItem.item.title {
            if title.starts(with: "Show HN: ") {
                newLocalizableItem.isShowHNStory = true
                newLocalizableItem.item.title = title.replacingOccurrences(of: "Show HN: ", with: "")
                newLocalizableItem.titleLocalized = try await translator
                    .translate(title.replacingOccurrences(of: "Show HN: ", with: ""))
            } else {
                newLocalizableItem.titleLocalized = try await translator
                    .translate(title)
            }
        }
        debugPrint("[\(id)] Localizing text...")
        if let textDeformatted = newLocalizableItem.textDeformatted() {
            newLocalizableItem.textLocalized = try await translator
                .translate(textDeformatted)
        } else {
            newLocalizableItem.textLocalized = try await translator
                .translate(storyItem.text ?? "")
        }
        debugPrint("[\(id)] Getting favicon...")
        if let url = storyItem.url {
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
                newLocalizableItem.faviconURL = fetchedFavicon.url.absoluteString
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        newLocalizableItem.cacheDate = Date()
        cache(newItem: newLocalizableItem)
        return newLocalizableItem
    }
    // swiftlint:enable function_body_length

    func fetchComments(ids: [Int],
                       translator: Translator,
                       fetchFreshComment: Bool = false,
                       commentFetchedAction: @escaping () -> Void) async -> [HNItemLocalizable] {
        let fetchedComments = await withTaskGroup(of: HNItemLocalizable?.self,
                                      returning: [HNItemLocalizable].self, body: { group in
            var comments: [HNItemLocalizable] = []
            for id in ids {
                group.addTask(priority: .high) {
                    do {
                        return try await self.comment(id: id,
                                                      translator: translator,
                                                      fetchFreshComment: fetchFreshComment)
                    } catch {
                        debugPrint(error.localizedDescription)
                        return nil
                    }
                }
            }
            for await result in group {
                if let result = result {
                    commentFetchedAction()
                    comments.append(result)
                }
            }
            return comments
        })
        var correctlyOrderedComments = [HNItemLocalizable]()
        for id in ids {
            if let fetchedComment = fetchedComments.first(where: { $0.id == id }) {
                correctlyOrderedComments.append(fetchedComment)
            }
        }
        saveCache()
        return correctlyOrderedComments
    }

    func comment(id: Int, translator: Translator, fetchFreshComment: Bool = false) async throws -> HNItemLocalizable {
        debugPrint("[\(id)] Attempting to get comment from cache...")
        if !fetchFreshComment,
           let loadedComment = cache[id] {
            return loadedComment
        }
        debugPrint("[\(id)] Attempting to fetch comment from API...")
        let commentItem = try await AF.request("\(apiEndpoint)/item/\(id).json",
                                             method: .get)
            .serializingDecodable(HNItem.self,
                                  decoder: JSONDecoder()).value
        debugPrint("[\(id)] Creating localizable object...")
        var newLocalizableItem = HNItemLocalizable(item: commentItem)
        debugPrint("[\(id)] Localizing text...")
        if let textDeformatted = newLocalizableItem.textDeformatted() {
            newLocalizableItem.textLocalized = try await translator
                .translate(textDeformatted)
        } else {
            newLocalizableItem.textLocalized = try await translator
                .translate(commentItem.text ?? "")
        }
        newLocalizableItem.cacheDate = Date()
        cache(newItem: newLocalizableItem)
        return newLocalizableItem
    }

    func usedCacheSpace() -> Int {
        return cacheInMemory.count
    }

    func cache(newItems: [HNItemLocalizable]) {
        for newItem in newItems {
            var newItemWithCacheDate = newItem
            newItemWithCacheDate.cacheDate = Date()
            debugPrint("[\(newItem.item.id)] Caching...")
            DispatchQueue.main.async { [self] in
                cache[newItem.item.id] = newItemWithCacheDate
            }
        }
    }

    func cache(newItem: HNItemLocalizable) {
        debugPrint("[\(newItem.item.id)] Caching...")
        DispatchQueue.main.async { [self] in
            cache[newItem.item.id] = newItem
        }
    }

    func saveCache() {
        do {
            debugPrint("Saving cache...")
            let encoded = try encoder.encode(cache)
            defaults.set(encoded, forKey: "MiniCache")
            DispatchQueue.main.async {
                self.cacheInMemory = encoded
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func clearCache() {
        cache.removeAll()
        saveCache()
    }

    func cleanUpCache() {
        let now = Date()
        for (key, value) in cache {
            if let cacheDate = value.cacheDate {
                if Calendar.current.dateComponents([.day], from: cacheDate, to: now).day ?? 0 >= 7 {
                    debugPrint("[\(key)] Removing from cache...")
                    cache[key] = nil
                }
            } else {
                debugPrint("[\(key)] Removing from cache...")
                cache[key] = nil
            }
        }
    }
}
