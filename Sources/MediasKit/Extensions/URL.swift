//
//  URL.swift
//  MediasKit
//
//  Created by Lucas Abijmil on 17/10/2024.
//

import Foundation

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
