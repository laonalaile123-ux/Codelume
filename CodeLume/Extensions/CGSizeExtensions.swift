//
//  CGSizeExtensions.swift
//  CodeLume
//
//  Created by 广子俞 on 2025/12/12.
//

import Foundation

extension CGSize {
    var stringValue: String {
        return "\(Int(width)) x \(Int(height))"
    }
    
    static func fromString(_ string: String) -> CGSize? {
        let components = string.split(separator: " x ").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        return CGSize(width: components[0], height: components[1])
    }

    init?(string: String) {
        guard let size = CGSize.fromString(string) else { return nil }
        self = size
    }
}
