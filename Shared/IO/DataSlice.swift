//
//  SmartData.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/24.
//

import Foundation

struct DataSlice: Equatable {
    
    static func == (lhs: DataSlice, rhs: DataSlice) -> Bool {
        return lhs.startOffset == rhs.startOffset && lhs.count == rhs.count && lhs.sameSource(with: rhs)
    }
    
    private let machoData: Data
    
    let startOffset: Int
    let count: Int
    
    let preferredNumberOfHexDigits: Int
    
    var raw: Data {
        return machoData[(machoData.startIndex + startOffset)..<(machoData.startIndex + startOffset + count)]
    }
    
    init(_ machoData: Data) {
        self.init(machoData, startOffset: .zero, length: machoData.count)
    }
    
    private init(_ machoData: Data, startOffset: Int, length: Int) {
        guard let magicType = MagicType(machoData), magicType.isMachoFile else { fatalError() }
        
        self.machoData = machoData
        self.startOffset = startOffset
        self.count = length
        
        var machoDataSize = machoData.count
        var digitCount = 0
        while machoDataSize != 0 {
            digitCount += 1
            machoDataSize /= 16
        }
        self.preferredNumberOfHexDigits = digitCount
    }
    
    func truncated(from: Int, maxLength: Int) -> DataSlice {
        if from + maxLength > self.count {
            return self.truncated(from: from)
        } else {
            return self.truncated(from: from, length: maxLength)
        }
    }
    
    func truncated(from: Int, length: Int? = nil) -> DataSlice {
        if let length = length {
            guard length > 0 else { fatalError() }
            guard from + length <= self.count else { fatalError() }
            return DataSlice(machoData, startOffset: startOffset + from, length: length)
        } else {
            guard from < self.count else { fatalError() }
            return DataSlice(machoData, startOffset: startOffset + from, length: self.count - from)
        }
    }
    
    func starts(with bytes: [UInt8]) -> Bool {
        return raw.starts(with: bytes)
    }
 
    func sameSource(with anotherSmartData: DataSlice) -> Bool {
        return self.machoData == anotherSmartData.machoData
    }
    
    static func merged(_ one: DataSlice, another: DataSlice) -> DataSlice {
        guard one.sameSource(with: another) else { fatalError() }
        
        // to merge one store with another, the data of nextStore must be consectutive with self's data
        // that is, self's data count plus self's lineTagStartIndex must be the nextStore's lineTagStartIndex
        guard one.startOffset + one.count == another.startOffset else { fatalError() }
        
        return DataSlice(one.machoData, startOffset: one.startOffset, length: one.count + another.count)
    }
}

extension DataSlice {
    func absoluteRange(_ start: Int, _ length: Int) -> Range<Int> {
        return startOffset+start..<startOffset+start+length
    }
    
    func absoluteRange(_ relativeRange: Range<Int>) -> Range<Int> {
        return startOffset+relativeRange.lowerBound..<startOffset+relativeRange.upperBound
    }
}
