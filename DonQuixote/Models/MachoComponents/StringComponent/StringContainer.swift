//
//  StringContainer.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

struct RawString {
    
    let offset: Int
    let data: Data
    var dataSize: Int { data.count }
    
    init(offset: Int, data: Data) {
        self.offset = offset
        self.data = data
    }
    
}

struct StringContent {
    let byteCount: Int
    let content: String?
    let demangled: String?
}

actor StringContainer {
        
    private let data: Data
    private let encoding: String.Encoding
    private let shouldDemangle: Bool
    
    private var _rawStrings: [RawString]?
    var rawStrings: [RawString] {
        get {
            if let _rawStrings { return _rawStrings }
            let ret = StringContainer.generateRawStrings(with: self.data, encoding: self.encoding)
            _rawStrings = ret
            return ret
        }
    }
    
    private var _rawStringQuickIndexByOffset: [Int:Int]?
    private var rawStringQuickIndexByOffset: [Int:Int] {
        get {
            if let _rawStringQuickIndexByOffset { return _rawStringQuickIndexByOffset }
            var ret: [Int:Int] = [:]
            for (index, rawString) in self.rawStrings.enumerated() {
                ret[rawString.offset] = index
            }
            _rawStringQuickIndexByOffset = ret
            return ret
        }
    }
    
    init(data: Data, encoding: String.Encoding, shouldDemangle: Bool) {
        self.data = data
        self.encoding = encoding
        self.shouldDemangle = shouldDemangle
    }
    
    private static func generateRawStrings(with data: Data, encoding: String.Encoding) -> [RawString] {
        
        var rawStrings: [RawString] = []
        let dataStartIndex = data.startIndex
        
        switch encoding {
        case .utf8:
            var currentIndex: Int = 0
            while currentIndex < data.count {
                while (data[dataStartIndex + currentIndex] == 0) {
                    currentIndex += 1
                    guard currentIndex < data.count else { /* meet end of the content */ return rawStrings }
                    continue
                }
                let stringStartIndex = currentIndex
                while (data[dataStartIndex + currentIndex] != 0) {
                    currentIndex += 1
                    guard currentIndex < data.count else { fatalError() }
                }
                let stringData = data[(data.startIndex + stringStartIndex)...(data.startIndex + currentIndex)]
                let rawString = RawString(offset: stringStartIndex, data: stringData)
                rawStrings.append(rawString)
            }
        case .utf16LittleEndian:
            let utf16UnitCount = data.count / 2
            var currentUnitIndex: Int = 0
            while currentUnitIndex < utf16UnitCount {
                while ((data.subSequence(from: currentUnitIndex * 2, count: 2).UInt16) == 0) {
                    currentUnitIndex += 1
                    guard currentUnitIndex < utf16UnitCount else { /* meet end of the content */ return rawStrings }
                    continue
                }
                let uStringUnitStartIndex = currentUnitIndex
                while ((data.subSequence(from: currentUnitIndex * 2, count: 2).UInt16) != 0) {
                    currentUnitIndex += 1
                    guard currentUnitIndex < utf16UnitCount else { fatalError() }
                }
                let stringStartIndex = uStringUnitStartIndex * 2
                let stringData = data[(data.startIndex + stringStartIndex)...(data.startIndex + currentUnitIndex * 2 + 1)]
                let rawString = RawString(offset: stringStartIndex, data: stringData)
                rawStrings.append(rawString)
            }
        default:
            fatalError()
        }
        
        return rawStrings
    }
 
    // public
    var numberOfStrings: Int {
        self.rawStrings.count
    }
    
    func stringContent(for rawString: RawString) -> StringContent {
        var stringValue: String?
        var demangled: String?
        if let _stringValue = String(data: rawString.data, encoding: self.encoding) {
            stringValue = _stringValue
            if self.shouldDemangle {
                if let _demangled = swift_demangle(_stringValue) {
                    demangled = _demangled
                }
            }
        }
        let stringContent = StringContent(byteCount: rawString.dataSize, content: stringValue, demangled: demangled)
        return stringContent
    }
    
    func stringContent(withOffset offset: Int) -> StringContent? {
        if let rawStringIndex = self.rawStringQuickIndexByOffset[offset] {
            return self.stringContent(for: self.rawStrings[rawStringIndex])
        }
        return nil
    }
    
}
