//
//  CacheEntry.swift
//  MediasKit
//
//  Created by Lucas Abijmil on 17/10/2024.
//

import Foundation

final class CacheEntry<Value: Codable>: Codable {
    let value: Value
    let expirationDate: Date

    init(value: Value, expirationDate: Date) {
        self.value = value
        self.expirationDate = expirationDate
    }
}
