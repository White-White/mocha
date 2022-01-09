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
    
    private let data: DataSlice
    private(set) var shifted: Int = .zero
    
    var shiftable: Bool { data.count > shifted }
    
    init(_ data: DataSlice) {
        self.data = data
    }
    
    mutating func shift(_ straddle: Straddle, updateIndex: Bool = true) -> Data {
        let num = straddle.raw
        guard num > 0 else { fatalError() }
        guard shifted + num <= data.count else { fatalError() }
        defer { if (updateIndex) { shifted += num } }
        return data.truncated(from: shifted, length: num).raw
    }
    
    mutating func skip(_ straddle: Straddle) {
        shifted += straddle.raw
    }
}
