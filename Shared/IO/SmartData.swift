//
//  SmartData.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/24.
//

import Foundation

protocol SmartDataContainer {
    var smartData: SmartData { get }
}

extension SmartDataContainer {
    var dataSize: Int { smartData.count }
    var startOffsetInMacho: Int { smartData.startOffsetInMacho }
    var endOffsetInMacho: Int { smartData.startOffsetInMacho + smartData.count }
}

struct SmartData: Equatable {
    static func == (lhs: SmartData, rhs: SmartData) -> Bool {
        return lhs.startOffsetInMacho == rhs.startOffsetInMacho && lhs.length == rhs.length && lhs.sameSource(with: rhs)
    }
    
    private let baseMachoData: Data
    let startOffsetInMacho: Int
    let bestHexDigits: Int
    private(set) var length: Int
    
    var count: Int { length }
    var raw: Data { baseMachoData[(baseMachoData.startIndex + startOffsetInMacho)..<(baseMachoData.startIndex + startOffsetInMacho + length)] }
    
    init(_ machoData: Data) {
        self.init(machoData, startOffsetInMacho: .zero, length: machoData.count)
    }
    
    private init(_ data: Data, startOffsetInMacho: Int, length: Int) {
        guard (startOffsetInMacho + length) <= data.count else { fatalError() }
        self.baseMachoData = data
        self.startOffsetInMacho = startOffsetInMacho
        self.length = length
        
        var machoDataSize = data.count
        var digitCount = 0
        while machoDataSize != 0 {
            digitCount += 1
            machoDataSize /= 16
        }
        self.bestHexDigits = digitCount
    }
    
    func truncated(from: Int, maxLength: Int) -> SmartData {
        if from + maxLength > self.length {
            return self.truncated(from: from)
        } else {
            return self.truncated(from: from, length: maxLength)
        }
    }
    
    func truncated(from: Int, length: Int? = nil) -> SmartData {
        if let length = length {
            guard length > 0 else { fatalError() }
            guard from + length <= self.length else { fatalError() }
            return SmartData(baseMachoData, startOffsetInMacho: startOffsetInMacho + from, length: length)
        } else {
            guard from < self.length else { fatalError() }
            return SmartData(baseMachoData, startOffsetInMacho: startOffsetInMacho + from, length: self.length - from)
        }
    }
    
    func starts(with bytes: [UInt8]) -> Bool {
        return raw.starts(with: bytes)
    }
 
    func sameSource(with anotherSmartData: SmartData) -> Bool {
        return self.baseMachoData == anotherSmartData.baseMachoData
    }
    
    mutating func extend(length: Int) {
        self.length += length
    }
    
    mutating func merge(_ another: SmartData) {
        guard sameSource(with: another) else { fatalError() }
        
        // to merge one store with another, the data of nextStore must be consectutive with self's data
        // that is, self's data count plus self's lineTagStartIndex must be the nextStore's lineTagStartIndex
        guard startOffsetInMacho + length == another.startOffsetInMacho else { fatalError() }
        
        // since they are all SmartData and have the same Data base,
        // all we need to do is to extend the length property of current store
        self.extend(length: another.length)
    }
}
