//
//  SmartData.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/24.
//

import Foundation

struct DataSlice: Equatable {
    
    static func == (lhs: DataSlice, rhs: DataSlice) -> Bool {
        return lhs.startIndex == rhs.startIndex && lhs.length == rhs.length && lhs.sameSource(with: rhs)
    }
    
    private let basedData: Data
    let startIndex: Int
    private let length: Int
    
    let preferredNumberOfHexDigits: Int
    
    var count: Int { length }
    var raw: Data { basedData[(basedData.startIndex + startIndex)..<(basedData.startIndex + startIndex + length)] }
    
    init(_ machoData: Data) {
        self.init(machoData, startOffsetInMacho: .zero, length: machoData.count)
    }
    
    private init(_ data: Data, startOffsetInMacho: Int, length: Int) {
        guard (startOffsetInMacho + length) <= data.count else { fatalError() }
        
        self.basedData = data
        self.startIndex = startOffsetInMacho
        self.length = length
        
        var machoDataSize = data.count
        var digitCount = 0
        while machoDataSize != 0 {
            digitCount += 1
            machoDataSize /= 16
        }
        self.preferredNumberOfHexDigits = digitCount
    }
    
    func truncated(from: Int, maxLength: Int) -> DataSlice {
        if from + maxLength > self.length {
            return self.truncated(from: from)
        } else {
            return self.truncated(from: from, length: maxLength)
        }
    }
    
    func truncated(from: Int, length: Int? = nil) -> DataSlice {
        if let length = length {
            guard length > 0 else { fatalError() }
            guard from + length <= self.length else { fatalError() }
            return DataSlice(basedData, startOffsetInMacho: startIndex + from, length: length)
        } else {
            guard from < self.length else { fatalError() }
            return DataSlice(basedData, startOffsetInMacho: startIndex + from, length: self.length - from)
        }
    }
    
    func starts(with bytes: [UInt8]) -> Bool {
        return raw.starts(with: bytes)
    }
 
    func sameSource(with anotherSmartData: DataSlice) -> Bool {
        return self.basedData == anotherSmartData.basedData
    }
    
    static func merged(_ one: DataSlice, another: DataSlice) -> DataSlice {
        guard one.sameSource(with: another) else { fatalError() }
        
        // to merge one store with another, the data of nextStore must be consectutive with self's data
        // that is, self's data count plus self's lineTagStartIndex must be the nextStore's lineTagStartIndex
        guard one.startIndex + one.length == another.startIndex else { fatalError() }
        
        return DataSlice(one.basedData, startOffsetInMacho: one.startIndex, length: one.length + another.length)
    }
}

extension DataSlice {
    func absoluteRange(_ start: Int, _ length: Int) -> Range<Int> {
        return startIndex+start..<startIndex+start+length
    }
    
    func absoluteRange(_ relativeRange: Range<Int>) -> Range<Int> {
        return startIndex+relativeRange.lowerBound..<startIndex+relativeRange.upperBound
    }
}
