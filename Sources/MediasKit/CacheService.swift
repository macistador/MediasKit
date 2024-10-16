//
//  File.swift
//  MediasKit
//
//  Created by Lucas Abijmil on 16/10/2024.
//

import Foundation

enum CacheType {
    case memory
    case disk
    case memoryAndDisk
}

protocol CacheServiceLogic: Actor {
    associatedtype Value
    associatedtype Key: Hashable

    func insert(_ value: Value, forKey key: Key)
    func value(forKey key: Key) -> Value?
    func removeValue(forKey key: Key)
    func clearCache()
}

final class CacheKey<T: Hashable>: NSObject {
    override var hash: Int {
        return key.hashValue
    }
    private let key: T

    init(_ key: T) {
        self.key = key
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let value = object as? CacheKey else { return false }
        return value.key == key
    }
}

final class CacheEntry<Value> {
    let value: Value
    let expirationDate: Date

    init(value: Value, expirationDate: Date) {
        self.value = value
        self.expirationDate = expirationDate
    }
}

actor CacheService<Key: Hashable, Value>: CacheServiceLogic {
    private let cache = NSCache<CacheKey<Key>, CacheEntry<Value>>()
    private let cacheCreation: Date = .now
    private let cacheExpiration: TimeInterval
    private let cacheType: CacheType

    init(countLimit: Int = 0, costLimit: Int = 0, expiration: TimeInterval = .oneDay, cacheType: CacheType = .memoryAndDisk) {
        cache.countLimit = countLimit
        cache.totalCostLimit = costLimit
        cacheExpiration = expiration
        self.cacheType = cacheType
    }

    func insert(_ value: Value, forKey key: Key) {
        let expirationDate = cacheCreation.addingTimeInterval(cacheExpiration)
        let entry = CacheEntry(value: value, expirationDate: expirationDate)
        cache.setObject(entry, forKey: CacheKey(key))
    }

    func value(forKey key: Key) -> Value? {
        guard let cacheEntry = cache.object(forKey: CacheKey(key)) else { return nil }
        guard cacheEntry.expirationDate > cacheCreation else {
            removeValue(forKey: key)
            return nil
        }
        return cacheEntry.value
    }

    func removeValue(forKey key: Key) {
        cache.removeObject(forKey: CacheKey(key))
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
