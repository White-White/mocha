//
//  InterpreterUtils.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/14.
//

import SwiftUI

struct LEB128 {
    let rawValue: Swift.UInt64
    let isSigned: Bool
    let byteCount: Int
}

struct CString {
    let rawValue: String
    let byteCount: Int
}

class InterpreterUtils {
    
    static func readULEB128(in data: Data, at offset: Int) -> LEB128 {
        let (delta, _, byteLength) = _readULEB128(in: data, at: offset)
        return LEB128(rawValue: delta, isSigned: false, byteCount: byteLength)
    }
    
    static func readSLEB128(in data: Data, at offset: Int) -> LEB128 {
        var (delta, shift, byteLength) = _readULEB128(in: data, at: offset)
        let signExtendMask: Swift.UInt64 = ~0
        delta |= signExtendMask << shift
        return LEB128(rawValue: delta, isSigned: true, byteCount: byteLength)
    }
    
    private static func _readULEB128(in data: Data, at offset: Int) -> (Swift.UInt64, Swift.UInt32, Int) {
        var index = offset
        var delta: Swift.UInt64 = 0
        var shift: Swift.UInt32 = 0
        var more = true
        repeat {
            let byte = data[data.startIndex+index]; index += 1
            delta |= ((Swift.UInt64(byte) & 0x7f) << shift)
            shift += 7
            if byte < 0x80 {
                more = false
            }
        } while (more)
        return (delta, shift, index - offset)
    }
    
    static func readUTF8String(in data: Data, at offset: Int, spacedRemoved: Bool = false) -> CString {
        var startIndex = offset
        while data[data.startIndex+startIndex] != 0 {
            startIndex += 1
        }
        let cStringByteLength = startIndex - offset + 1
        guard let cString = data.select(from: offset, length: cStringByteLength).utf8String else {
            // invalid utf8 string in dyld exported info trie. this is unexpected
            fatalError()
        }
        return CString(rawValue: spacedRemoved ? cString.spaceRemoved : cString, byteCount: cStringByteLength)
    }
}
