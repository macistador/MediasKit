//
//  CacheKey.swift
//  MediasKit
//
//  Created by Lucas Abijmil on 17/10/2024.
//

import Foundation

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
