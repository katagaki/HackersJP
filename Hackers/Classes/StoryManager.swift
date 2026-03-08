//
//  StoryManager.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import Foundation
import SQLite

class StoryManager: ObservableObject {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    var cache: [Int: HNItemLocalizable] = [:]
    @Published var cacheSize: Int64 = 0

    let database: Connection?

    // SQLite table definition
    let cacheTable = Table("cache")
    let colId = SQLite.Expression<Int>("id")
    let colData = SQLite.Expression<Data>("data")
    let colCacheDate = SQLite.Expression<Date>("cache_date")

    init() {
        // Open database in group container
        database = Self.openDatabase()
        if let database = database {
            do {
                let cacheTable = self.cacheTable
                let colId = self.colId
                let colData = self.colData
                let colCacheDate = self.colCacheDate
                try database.run(cacheTable.create(ifNotExists: true) { table in
                    table.column(colId, primaryKey: true)
                    table.column(colData)
                    table.column(colCacheDate)
                })
            } catch {
                #if DEBUG
                debugPrint("Failed to create table: \(error.localizedDescription)")
                #endif
            }
        }

        migrateFromUserDefaults()
        loadCacheFromDB()
    }

    private static func openDatabase() -> Connection? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.Hackers"
        ) else {
            #if DEBUG
            debugPrint("Failed to find group container.")
            #endif
            return nil
        }
        let databasePath = containerURL.appendingPathComponent("Cache.hackers").path
        do {
            return try Connection(databasePath)
        } catch {
            #if DEBUG
            debugPrint("Failed to open database: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    private func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        guard let data = defaults.data(forKey: "MiniCache") else { return }
        guard let database = database else { return }
        do {
            let oldCache = try decoder.decode([Int: HNItemLocalizable].self, from: data)
            if !oldCache.isEmpty {
                try database.transaction {
                    for (id, item) in oldCache {
                        let itemData = try self.encoder.encode(item)
                        try database.run(self.cacheTable.insert(or: .ignore,
                                                          self.colId <- id,
                                                          self.colData <- itemData,
                                                          self.colCacheDate <- item.cacheDate ?? Date()))
                    }
                }
                #if DEBUG
                debugPrint("Migrated \(oldCache.count) item(s) from UserDefaults to SQLite.")
                #endif
            }
        } catch {
            #if DEBUG
            debugPrint("Failed to migrate old cache: \(error.localizedDescription)")
            #endif
        }
        defaults.removeObject(forKey: "MiniCache")
    }

    private func loadCacheFromDB() {
        guard let database = database else { return }
        do {
            var loaded: [Int: HNItemLocalizable] = [:]
            for row in try database.prepare(cacheTable) {
                let data = row[colData]
                var item = try decoder.decode(HNItemLocalizable.self, from: data)
                item.cacheDate = row[colCacheDate]
                loaded[row[colId]] = item
            }
            cache = loaded
            #if DEBUG
            debugPrint("\(cache.count) item(s) loaded from cache.")
            #endif
            updateCacheSize()
        } catch {
            #if DEBUG
            debugPrint("Failed to load cache: \(error.localizedDescription)")
            #endif
        }
    }

    func updateCacheSize() {
        guard database != nil else {
            cacheSize = 0
            return
        }
        do {
            if let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.tsubuzaki.Hackers"
            ) {
                let databasePath = containerURL.appendingPathComponent("Cache.hackers").path
                let attrs = try FileManager.default.attributesOfItem(atPath: databasePath)
                let fileSize = attrs[.size] as? Int64 ?? 0
                DispatchQueue.main.async {
                    self.cacheSize = fileSize
                }
            }
        } catch {
            #if DEBUG
            debugPrint("Failed to get cache size: \(error.localizedDescription)")
            #endif
        }
    }
}
