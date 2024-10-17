//
//  File.swift
//  MediasKit
//
//  Created by Lucas Abijmil on 16/10/2024.
//

import Foundation

protocol CacheServiceLogic: Actor {
    associatedtype Value: Codable
    associatedtype Key: Hashable

    func insert(_ value: Value, forKey key: Key)
    func value(forKey key: Key) -> Value?
    func remove(forKey key: Key)
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
        let entry = CacheEntry(value: value, expirationDate: creationDate.addingTimeInterval(expirationTime))
        insertInMemory(entry, forKey: key)
        try? insertInDisk(entry, forKey: key)
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

    // MARK: - Memory
    private func insertInMemory(_ entry: CacheEntry<Value>, forKey key: Key) {
        guard isMemoryType else { return }
        memory.setObject(entry, forKey: CacheKey(key))
    }

    private func valueInMemory(forKey key: Key) -> Value? {
        guard isMemoryType, let cacheEntry = memory.object(forKey: CacheKey(key)) else { return nil }
        guard cacheEntry.expirationDate > creationDate else {
            removeInMemory(forKey: key)
            return nil
        }
        return cacheEntry.value
    }

    private func removeInMemory(forKey key: Key) {
        guard isMemoryType else { return }
        memory.removeObject(forKey: CacheKey(key))
    }

    // MARK: - Disk
    private func insertInDisk(_ entry: CacheEntry<Value>, forKey key: Key) throws {
        guard isDiskType else { return }
        let cachedFileURL = disk.appendingPathComponent(CacheKey(key).pathComponent) // Pas sûr de ça?? 🔍
        let data = try JSONEncoder().encode(entry)
        try data.write(to: cachedFileURL)
    }

    private func valueInDisk(forKey key: Key) throws -> Value? {
        guard isDiskType, let data = fileManager.contents(atPath: disk.appendingPathComponent(CacheKey(key).pathComponent).absoluteString) else { return nil }
        let cacheEntry = try JSONDecoder().decode(CacheEntry<Value>.self, from: data)
        guard cacheEntry.expirationDate > creationDate else {
            removeInDisk(forKey: key)
            return nil
        }
        return cacheEntry.value
    }

    private func removeInDisk(forKey key: Key) {
        guard isDiskType else { return }
        try? fileManager.removeItem(at: disk.appendingPathComponent(CacheKey(key).pathComponent))
    }
}
