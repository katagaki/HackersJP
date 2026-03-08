//
//  StoryManager+Cache.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import Foundation
import SQLite

extension StoryManager {

    // MARK: - Cache

    func usedCacheSpace() -> Int64 {
        return cacheSize
    }

    func cache(newItems: [HNItemLocalizable]) {
        for newItem in newItems {
            cache(newItem: newItem)
        }
    }

    func cache(newItem: HNItemLocalizable) {
        guard let database = database else { return }
        var newItemWithCacheDate = newItem
        newItemWithCacheDate.cacheDate = Date()
        #if DEBUG
        debugPrint("[\(newItem.item.id)] Caching...")
        #endif
        do {
            let data = try encoder.encode(newItemWithCacheDate)
            try database.run(cacheTable.insert(or: .replace,
                                         colId <- newItemWithCacheDate.item.id,
                                         colData <- data,
                                         colCacheDate <- newItemWithCacheDate.cacheDate ?? Date()))
            DispatchQueue.main.async { [self] in
                cache[newItemWithCacheDate.item.id] = newItemWithCacheDate
            }
        } catch {
            #if DEBUG
            debugPrint("[\(newItem.item.id)] Failed to cache: \(error.localizedDescription)")
            #endif
        }
    }

    func saveCache() {
        // With SQLite, items are persisted on write, so this is now a no-op.
        // Kept for API compatibility.
        updateCacheSize()
    }

    func clearCache() {
        guard let database = database else { return }
        do {
            try database.run(cacheTable.delete())
            try database.execute("VACUUM")
            DispatchQueue.main.async { [self] in
                cache.removeAll()
            }
            updateCacheSize()
        } catch {
            #if DEBUG
            debugPrint("Failed to clear cache: \(error.localizedDescription)")
            #endif
        }
    }

    func cleanUpCache() {
        guard let database = database else { return }
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        do {
            let staleRows = cacheTable.filter(colCacheDate < sevenDaysAgo)
            let deletedCount = try database.run(staleRows.delete())
            #if DEBUG
            if deletedCount > 0 {
                debugPrint("Removed \(deletedCount) stale item(s) from cache.")
            }
            #endif
            // Also clean in-memory cache
            DispatchQueue.main.async { [self] in
                for (key, value) in cache {
                    if let cacheDate = value.cacheDate, cacheDate < sevenDaysAgo {
                        cache[key] = nil
                    } else if value.cacheDate == nil {
                        cache[key] = nil
                    }
                }
            }
            updateCacheSize()
        } catch {
            #if DEBUG
            debugPrint("Failed to clean up cache: \(error.localizedDescription)")
            #endif
        }
    }
}
