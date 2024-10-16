//
//  File.swift
//  MediasKit
//
//  Created by Lucas Abijmil on 16/10/2024.
//

import Foundation

// Do we want to be that specific?
enum CacheType {
    case memory
    case disk
}

protocol CacheServiceLogic: Actor {
    associatedtype Value
    associatedtype Key: Hashable

    func insert(_ value: Value, forKey key: Key, in cacheType: CacheType)
    func value(forKey key: Key, in cacheType: CacheType) -> Value?
    func removeValue(forKey key: Key, in cacheType: CacheType)
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
    private let cacheExpiration: TimeInterval
    private let cacheCreation: Date = .now

    init(countLimit: Int = 0, costLimit: Int = 0, expiration: TimeInterval = .oneDay) {
        cache.countLimit = countLimit
        cache.totalCostLimit = costLimit
        cacheExpiration = expiration
    }

    func insert(_ value: Value, forKey key: Key, in cacheType: CacheType) {
        switch cacheType {
        case .memory:
            let expirationDate = cacheCreation.addingTimeInterval(cacheExpiration)
            let entry = CacheEntry(value: value, expirationDate: expirationDate)
            cache.setObject(entry, forKey: CacheKey(key))
        case .disk:
            break // TODO:
        }
    }

    func value(forKey key: Key, in cacheType: CacheType) -> Value? {
        switch cacheType {
        case .memory:
            guard let cacheEntry = cache.object(forKey: CacheKey(key)) else { return nil }
            guard cacheEntry.expirationDate > cacheCreation else {
                removeValue(forKey: key, in: cacheType)
                return nil
            }
            return cacheEntry.value
        case .disk:
            return nil // TODO:
        }
    }

    func removeValue(forKey key: Key, in cacheType: CacheType) {
        switch cacheType {
        case .memory:
            cache.removeObject(forKey: CacheKey(key))
        case .disk:
            break // TODO: 
        }
    }
}


