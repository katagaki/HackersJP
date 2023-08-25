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
    @Published var items: [HNItemLocalizable] = []

    init() {
        if defaults.value(forKey: "MiniCache") == nil {
            do {
                let encoded = try encoder.encode([HNItemLocalizable]())
                defaults.set(encoded, forKey: "MiniCache")
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        
        do {
            if let data = defaults.data(forKey: "MiniCache") {
                items = try decoder.decode([HNItemLocalizable].self, from: data)
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
        items = []
        saveCache()
    }

    func cache(newItem: HNItemLocalizable) {
        DispatchQueue.main.async { [self] in
            items.removeAll { item in
                item.item.id == newItem.id
            }
            items.append(newItem)
            saveCache()
        }
    }

    func item(for id: Int) -> HNItemLocalizable? {
        if let item = items.first(where: { item in
            item.item.id == id
        }) {
            return item
        } else {
            return nil
        }
    }

    func saveCache() {
        do {
            let encoded = try encoder.encode(items)
            defaults.set(encoded, forKey: "MiniCache")
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}
