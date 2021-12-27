//
//  FileSize.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/5.
//

import Foundation

struct FileSize {
    let bytes: Int
    var string: String {
        return String(format: "FileSize: 0x%X", bytes)
    }
    init(_ bytes: Int) {
        self.bytes = bytes
    }
}
