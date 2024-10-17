//
//  File.swift
//  MediasKit
//
//  Created by Michel-André Chirita on 07/10/2024.
//

import SwiftUI

public enum MediaSource {
    case remote(URL)
    case uiImage(UIImage)
    case image(Image)
    case data(Data)
}
