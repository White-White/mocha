//
//  KnownError.swift
//  mocha (macOS)
//
//  Created by white on 2023/5/12.
//

import Foundation

enum KnownErrorType {
    case document
    case machoMetaError
}

struct KnownError: Error {
    let type: KnownErrorType
}
