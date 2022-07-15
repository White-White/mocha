//
//  Utils.swift
//  mocha
//
//  Created by white on 2021/6/17.
//

import Foundation
import SwiftUI

extension Data {
    
    private func cast<T>(to type: T.Type) -> T {
        guard self.count == MemoryLayout<T>.size else { fatalError() }
        return self.withUnsafeBytes { $0.bindMemory(to: type).baseAddress!.pointee }
    }
    
    var UInt8: Swift.UInt8 { if (self.count == 1) { return self.first! } else { fatalError() } }
    var UInt16: Swift.UInt16 { cast(to: Swift.UInt16.self) }
    var UInt32: Swift.UInt32 { cast(to: Swift.UInt32.self) }
    var UInt64: Swift.UInt64 { cast(to: Swift.UInt64.self) }
    var utf8String: String? { String(data: self, encoding: .utf8) }
    
    func subSequence(from: Int, maxCount: Int) -> Data {
        if from + maxCount > self.count {
            return self.subSequence(from: from)
        } else {
            return self.subSequence(from: from, count: maxCount)
        }
    }
    
    func subSequence(from: Int, count: Int? = nil) -> Data {
        if let count = count {
            if count == .zero {
                Log.error("Trying to fetch zero-length data. Crash is around the corner.")
            }
            guard from + count <= self.count else { fatalError() }
            return self[self.startIndex+from..<self.startIndex+from+count]
        } else {
            guard from < self.count else { fatalError() }
            return self[self.startIndex+from..<self.endIndex]
        }
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

extension RandomAccessCollection {
    /// Finds such index N that predicate is true for all elements up to
    /// but not including the index N, and is false for all elements
    /// starting with index N.
    /// Behavior is undefined if there is no such N.
    func binarySearch(predicate: (Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}

