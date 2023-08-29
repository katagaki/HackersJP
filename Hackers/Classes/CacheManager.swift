//
//  CacheManager.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/25.
//

import Foundation

class CacheManager: ObservableObject {

    let defaults = UserDefaults.standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    @Published var items: [Int: HNItemLocalizable] = [:]

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
                items = try decoder.decode([Int: HNItemLocalizable].self, from: data)
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func usedSpace() -> Int {
        if let data = defaults.data(forKey: "MiniCache") {
            return data.count
        }
        return 0
    }

    func clear() {
        items.removeAll()
        save()
    }
    
    func cache(newItems: [HNItemLocalizable]) {
        for newItem in newItems {
            debugPrint("[\(newItem.item.id)] Caching...")
            DispatchQueue.main.async { [self] in
                items[newItem.item.id] = newItem
            }
        }
        save()
    }

    func cache(newItem: HNItemLocalizable) {
        debugPrint("[\(newItem.item.id)] Caching...")
        DispatchQueue.main.async { [self] in
            items[newItem.item.id] = newItem
            save()
        }
    }

    func item(for id: Int) -> HNItemLocalizable? {
        if let item = items[id] {
            return item
        } else {
            return nil
        }
    }

    func save() {
        do {
            let encoded = try encoder.encode(items)
            defaults.set(encoded, forKey: "MiniCache")
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func cleanUp() {
        let now = Date()
        for (key, value) in items {
            if let cacheDate = value.cacheDate {
                if Calendar.current.dateComponents([.day], from: cacheDate, to: now).day ?? 0 >= 7 {
                    items[key] = nil
                }
            } else {
                items[key] = nil
            }
        }
    }
}
