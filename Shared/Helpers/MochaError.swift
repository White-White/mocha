//
//  MochaError.swift
//  mocha
//
//  Created by white on 2021/6/15.
//

import Foundation

struct MochaError: Error {
    enum MochaErrorType {
        case unknownMagicType
        case failedToParseARHeader
        case ARFileMagicCheckFailed
    }
    
    let type: MochaErrorType
    init(_ type: MochaErrorType) { self.type = type }
}
