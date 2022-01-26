//
//  Utils.swift
//  mocha
//
//  Created by white on 2021/6/17.
//

import Foundation
import SwiftUI

extension Data {
    var UInt8: UInt8 {
        if (self.count != 1) { fatalError() }
        return self.first!
    }
    var UInt16: UInt16 {
        if (self.count != 2) { fatalError() }
        return self.withUnsafeBytes { $0.load(as: Swift.UInt16.self) }
    }
    var UInt32: UInt32 {
        if (self.count != 4) { fatalError() }
        return self.withUnsafeBytes { $0.load(as: Swift.UInt32.self) }
    }
    var UInt64: UInt64 {
        if self.count == 4 {
            return Swift.UInt64(self.UInt32)
        } else if self.count == 8 {
            return self.withUnsafeBytes { $0.load(as: Swift.UInt64.self) }
        } else {
            fatalError()
        }
    }
    
    func select(from: Data.Index, length: Data.Index) -> Self {
        return self[self.startIndex+from..<self.startIndex+from+length]
    }
    
    var utf8String: String? {
        return String(data: self, encoding: .utf8)
    }
}

extension String {
    var spaceRemoved: String {
        return self.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\0", with: "")
    }
}

extension Int {
    var hex: String { String(format: "0x%0X", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

extension UInt16 {
    var hex: String { String(format: "0x%0X", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

extension UInt32 {
    var hex: String { String(format: "0x%0X", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

extension UInt64 {
    var hex: String { String(format: "0x%llX", self) }
    var isNotZero: Bool { self != .zero }
    func bitAnd(_ v: Self) -> Bool { self & v != 0}
}

class Utils {
    
    struct TickTock {
        let time = CACurrentMediaTime() * 1000
        let name: String
    }
    
    static func makeRange(start: Int, length: Int) -> Range<Int> {
        return start..<start+length
    }
    static func range(after range: Range<Int>, distance: Int = 0, length: Int) -> Range<Int> {
        guard length != 0 else { fatalError() }
        return range.upperBound+distance..<range.upperBound+distance+length
    }
    
    static func tick(_ name: String) -> TickTock {
        return TickTock(name: name)
    }
    
    static func tock(_ tickTock: TickTock) {
        let timeGap = CACurrentMediaTime() * 1000 - tickTock.time
        print("\n \(tickTock.name)'s Time Usage:")
        print("--- \(timeGap) ms. ---")
    }
}

