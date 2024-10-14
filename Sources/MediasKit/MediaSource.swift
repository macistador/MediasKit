//
//  File.swift
//  MediasKit
//
//  Created by Michel-André Chirita on 07/10/2024.
//

import UIKit

public enum MediaSource {
    case remote(URL)
    case image(UIImage)
    case data(Data)
    case asset(ImageResource)
}
