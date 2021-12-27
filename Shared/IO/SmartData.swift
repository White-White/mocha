//
//  SmartData.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/24.
//

import Foundation

struct SmartData {
    
    let id: UUID
    private let dataInside: Data
    private let startIndex: Int
    private var length: Int
    
    var count: Int { length }
    var realData: Data { dataInside[(dataInside.startIndex + startIndex)..<(dataInside.startIndex + startIndex + length)] }
    
    init(_ data: Data) {
        self.init(data, startIndex: .zero, length: data.count, id: UUID())
    }
    
    private init(_ data: Data, startIndex: Int, length: Int, id: UUID) {
        guard (startIndex + length) <= data.count else { fatalError() }
        self.dataInside = data
        self.startIndex = startIndex
        self.length = length
        self.id = id
    }
    
    func select(from: Int, length: Int? = nil) -> SmartData {
        if let length = length {
            guard length > 0 else { fatalError() }
            guard from + length <= self.length else { fatalError() }
            return SmartData(dataInside, startIndex: startIndex + from, length: length, id: self.id)
        } else {
            guard from < self.length else { fatalError() }
            return SmartData(dataInside, startIndex: startIndex + from, length: self.length - from, id: self.id)
        }
    }
    
    func select(from: Int, maxLength: Int) -> SmartData {
        if from + maxLength > self.length {
            return self.select(from: from)
        } else {
            return self.select(from: from, length: maxLength)
        }
    }
    
    func starts(with bytes: [UInt8]) -> Bool {
        return dataInside[startIndex...].starts(with: bytes)
    }
 
    func sameSource(with anotherSmartData: SmartData) -> Bool {
        return self.id == anotherSmartData.id
    }
    
    mutating func extend(length: Int) {
        self.length += length
    }
}
