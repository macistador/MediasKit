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
    associatedtype Value: Codable
    associatedtype Key: Hashable

    func insert(_ value: Value, forKey key: Key)
    func value(forKey key: Key) -> Value?
    func remove(forKey key: Key)
    func removeAll()
}

final class CacheKey<T: Hashable>: NSObject {
    override var hash: Int {
        return key.hashValue
    }
    var pathComponent: String {
        return hash.description + ".cache"
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

final class CacheEntry<Value: Decodable> {
    let value: Value
    let expirationDate: Date

    init(value: Value, expirationDate: Date) {
        self.value = value
        self.expirationDate = expirationDate
    }
}

extension URL {

    @available(iOS, obsoleted: 16.0, message: "Use the URL.cachesDirectory built-in property")
    static var cachesDirectory: URL {
        if #available(iOS 16.0, *) {
            return URL.cachesDirectory
        } else {
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        }
    }
}

actor CacheService<Key: Hashable, Value: Codable>: CacheServiceLogic {
    private let memory = NSCache<CacheKey<Key>, CacheEntry<Value>>()
    private let disk = URL.cachesDirectory
    private let creationDate: Date = .now
    private let expirationTime: TimeInterval
    private let type: CacheType
    private let fileManager: FileManager
    private var isMemoryType: Bool {
        return type == .memory || type == .memoryAndDisk
    }
    private var isDiskType: Bool {
        return type == .disk || type == .memoryAndDisk
    }

    init(countLimit: Int = 0, costLimit: Int = 0, expirationTime: TimeInterval = .oneDay, type: CacheType = .memoryAndDisk, fileManager: FileManager = .default) {
        memory.countLimit = countLimit
        memory.totalCostLimit = costLimit
        self.expirationTime = expirationTime
        self.type = type
        self.fileManager = fileManager
    }

    func insert(_ value: Value, forKey key: Key) {
        insertInMemory(value, forKey: key)
        try? insertInDisk(value, forKey: key)
    }

    func value(forKey key: Key) -> Value? {
        if let valueInMemory = valueInMemory(forKey: key) {
            return valueInMemory
        } else if let valueInDisk = try? valueInDisk(forKey: key) {
            return valueInDisk
        } else {
            return nil
        }
    }

    func remove(forKey key: Key) {
        removeInMemory(forKey: key)
        removeInDisk(forKey: key)
    }

    func removeAll() {
        removeAllInMemory()
        removeAllInDisk()
    }

    // MARK: - Memory
    private func insertInMemory(_ value: Value, forKey key: Key) {
        guard isMemoryType else { return }
        let expirationDate = creationDate.addingTimeInterval(expirationTime)
        let entry = CacheEntry(value: value, expirationDate: expirationDate)
        memory.setObject(entry, forKey: CacheKey(key))
    }

    private func valueInMemory(forKey key: Key) -> Value? {
        guard isMemoryType, let cacheEntry = memory.object(forKey: CacheKey(key)) else { return nil }
        guard cacheEntry.expirationDate > creationDate else {
            remove(forKey: key)
            return nil
        }
        return cacheEntry.value
    }

    private func removeInMemory(forKey key: Key) {
        guard isMemoryType else { return }
        memory.removeObject(forKey: CacheKey(key))
    }

    private func removeAllInMemory() {
        guard isMemoryType else { return }
        memory.removeAllObjects()
    }

    // MARK: - Disk
    private func insertInDisk(_ value: Value, forKey key: Key) throws {
        guard isDiskType else { return }
        let cachedFileURL = disk.appendingPathComponent(CacheKey(key).pathComponent) // Pas sûr de ça?? 🔍
        let data = try JSONEncoder().encode(CacheEntry(value: value, expirationDate: expirationTime))
        try data.write(to: cachedFileURL)
    }

    // TODO:
    private func valueInDisk(forKey key: Key) throws -> Value? {
        guard isDiskType,
              let data = fileManager.contents(atPath: disk.appendingPathComponent(CacheKey(key).pathComponent).path),
              let cacheEntry = try JSONDecoder().decode(Value.self, from: data)
        else { return nil }

        return cacheEntry.value
    }

    // TODO:
    private func removeInDisk(forKey key: Key) {
        guard isDiskType else { return }
    }

    // TODO:
    private func removeAllInDisk() {
        guard isDiskType else { return }
    }
}
