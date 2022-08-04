//
//  DataShifter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/7.
//

import Foundation

enum Straddle {
    case word
    case doubleWords
    case quadWords
    case rawNumber(Int)
    
    var raw: Int {
        switch self {
        case .word:
            return 2
        case .doubleWords:
            return 4
        case .quadWords:
            return 8
        case .rawNumber(let rawValue):
            return rawValue
        }
    }
}

struct DataShifter {
    
    private let data: Data
    private(set) var shifted: Int = .zero
    var shiftable: Bool { data.count > shifted }
    
    init(_ data: Data) {
        self.data = data
    }
    
    mutating func shift(_ straddle: Straddle) -> Data {
        let num = straddle.raw
        guard num > 0 else { fatalError() }
        guard shifted + num <= data.count else { fatalError() }
        let selectedData = data.subSequence(from: shifted, count: num)
        shifted += num
        return selectedData
    }
    
    mutating func skip(_ straddle: Straddle) {
        shifted += straddle.raw
    }
    
    mutating func back(_ straddle: Straddle) {
        guard shifted >= straddle.raw else { fatalError() }
        shifted -= straddle.raw
    }
    
    mutating func shiftUInt64() -> UInt64 { self.shift(.quadWords).UInt64 }
    mutating func shiftUInt32() -> UInt32 { self.shift(.doubleWords).UInt32 }
    mutating func shiftInt32() -> Int32 { self.shift(.doubleWords).Int32 }
    mutating func shiftUInt16() -> UInt16 { self.shift(.word).UInt16 }
    mutating func shiftUInt8() -> UInt8 { self.shift(.rawNumber(1)).UInt8 }
    
}
