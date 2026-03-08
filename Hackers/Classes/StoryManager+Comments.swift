//
//  StoryManager+Comments.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import Alamofire
import Foundation
import MLKitTranslate

extension StoryManager {

    // MARK: - Comments

    func fetchComments(ids: [Int],
                       translator: Translator,
                       translationService: Int = 0,
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
                                                      translationService: translationService,
                                                      fetchFreshComment: fetchFreshComment)
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

    func comment(id: Int,
                 translator: Translator,
                 translationService: Int = 0,
                 fetchFreshComment: Bool = false) async throws -> HNItemLocalizable {
        #if DEBUG
        debugPrint("[\(id)] Attempting to get comment from cache...")
        #endif
        if !fetchFreshComment,
           let loadedComment = cache[id] {
            return loadedComment
        }
        #if DEBUG
        debugPrint("[\(id)] Attempting to fetch comment from API...")
        #endif
        let commentItem = try await AF.request("\(apiEndpoint)/item/\(id).json",
                                             method: .get)
            .serializingDecodable(HNItem.self,
                                  decoder: JSONDecoder()).value
        #if DEBUG
        debugPrint("[\(id)] Creating localizable object...")
        #endif
        var newLocalizableItem = HNItemLocalizable(item: commentItem)
        #if DEBUG
        debugPrint("[\(id)] Localizing text...")
        #endif
        if let textDeformatted = newLocalizableItem.textDeformatted() {
            newLocalizableItem.textLocalized = try await translateText(
                textDeformatted,
                translator: translator,
                translationService: translationService)
        } else {
            newLocalizableItem.textLocalized = try await translateText(
                commentItem.text ?? "",
                translator: translator,
                translationService: translationService)
        }
        newLocalizableItem.cacheDate = Date()
        cache(newItem: newLocalizableItem)
        return newLocalizableItem
    }

    // MARK: - Nested Comment Tree Fetching

    func fetchCommentTree(ids: [Int],
                          depth: Int = 0,
                          translator: Translator,
                          translationService: Int = 0,
                          fetchFreshComment: Bool = false,
                          commentFetchedAction: @escaping () -> Void) async -> [FlatComment] {
        let fetchedComments = await withTaskGroup(of: (Int, HNItemLocalizable?).self,
                                      returning: [Int: HNItemLocalizable].self) { group in
            var results = [Int: HNItemLocalizable]()
            for id in ids {
                group.addTask(priority: .high) {
                    do {
                        return (id, try await self.comment(id: id,
                                                           translator: translator,
                                                           translationService: translationService,
                                                           fetchFreshComment: fetchFreshComment))
                    } catch {
                        #if DEBUG
                        debugPrint(error.localizedDescription)
                        #endif
                        return (id, nil)
                    }
                }
            }
            for await result in group {
                if let comment = result.1 {
                    results[result.0] = comment
                }
            }
            return results
        }

        // Fetch all child subtrees concurrently
        let childTrees = await withTaskGroup(of: (Int, [FlatComment]).self,
                                              returning: [Int: [FlatComment]].self) { group in
            var trees = [Int: [FlatComment]]()
            for id in ids {
                guard let comment = fetchedComments[id] else { continue }
                if let kids = comment.item.kids, !kids.isEmpty {
                    group.addTask(priority: .high) {
                        let children = await self.fetchCommentTree(ids: kids,
                                                                    depth: depth + 1,
                                                                    translator: translator,
                                                                    translationService: translationService,
                                                                    fetchFreshComment: fetchFreshComment,
                                                                    commentFetchedAction: commentFetchedAction)
                        return (id, children)
                    }
                }
            }
            for await (id, children) in group {
                trees[id] = children
            }
            return trees
        }

        // Assemble results in original order
        var result = [FlatComment]()
        for id in ids {
            guard let comment = fetchedComments[id] else { continue }
            commentFetchedAction()
            result.append(FlatComment(comment: comment, depth: depth))
            if let children = childTrees[id] {
                result.append(contentsOf: children)
            }
        }
        if depth == 0 {
            saveCache()
        }
        return result
    }
}
