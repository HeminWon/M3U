//
//  M3uError.swift
//  M3U
//
//  Created by Hemin Won on 2022/5/1.
//  Copyright © 2022 HeminWon. All rights reserved.
//

import Foundation

public enum M3uError: Error {
    case invalidEXTM3U
}

extension M3uError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidEXTM3U:
            return "#EXTM3U "
        }
    }
}
