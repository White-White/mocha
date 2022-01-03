//
//  Utils.swift
//  mocha
//
//  Created by white on 2021/6/17.
//

import Foundation
import SwiftUI

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

extension Data {
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

func localized(_ string: String, _ content: String) -> String {
    return content
}

struct DataShifter {
    
    private let data: DataSlice
    private(set) var shifted: Int = .zero
    
    var shiftable: Bool { data.count > shifted }
    
    init(_ data: DataSlice) {
        self.data = data
    }
    
    mutating func nextWord() -> Data {
        return shift(2)
    }
    
    mutating func nextDoubleWord() -> Data {
        return shift(4)
    }
    
    mutating func nextQuadWord() -> Data {
        return shift(8)
    }
    
    mutating func shiftAll() -> Data {
        return shift(data.count - shifted)
    }
    
    mutating func shift(_ num: Int, updateIndex: Bool = true) -> Data {
        guard shifted + num <= data.count else { fatalError() }
        defer { if (updateIndex) { shifted += num } }
        return data.truncated(from: shifted, length: num).raw
    }
    
    mutating func ignore(_ num: Int) {
        shifted += num
    }
}

extension Int {
    var hex: String { String(format: "0x%0X", self) }
}
extension UInt16 {
    var hex: String { String(format: "0x%0X", self) }
}
extension UInt32 {
    var hex: String { String(format: "0x%0X", self) }
}
extension UInt64 {
    var hex: String { String(format: "0x%0X", self) }
}

