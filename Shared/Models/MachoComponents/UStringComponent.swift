//
//  UStringComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/26.
//

import Foundation

struct UStringPosition {
    let relativeStartOffset: Int
    let length: Int
}

class UStringComponent: MachoComponentWithTranslations {
    
    let uStringPositions: [UStringPosition]
    
    init(_ data: Data, title: String) {
        let dataLength = data.count
        let utf16UnitCount = dataLength / 2
        var uStringPositions: [UStringPosition] = []
        var indexOfLastNull = -2
        for index in 0..<utf16UnitCount {
            let curNullIndex = index * 2
            let utf16UnitValue = data.subSequence(from: curNullIndex, count: 2).UInt16
            if utf16UnitValue != 0 { continue }
            
            let uStringStartIndex = indexOfLastNull + 2
            let uStringDataLength = curNullIndex - uStringStartIndex
            if uStringDataLength == 0 { continue }
            
            let uStringPosition = UStringPosition(relativeStartOffset: uStringStartIndex,
                                                  length: uStringDataLength)
            uStringPositions.append(uStringPosition)
            indexOfLastNull = curNullIndex
        }
        self.uStringPositions = uStringPositions
        
        super.init(data, title: title)
    }
    
    override func createTranslations() -> [Translation] {
        return self.uStringPositions.map { self.translation(at: $0) }
    }
    
    private func translation(at uStringPosition: UStringPosition) -> Translation {
        var translation: Translation
        if let string = String(data: self.data.subSequence(from: uStringPosition.relativeStartOffset, count: uStringPosition.length), encoding: .utf16LittleEndian) {
            translation = Translation(definition: "UTF16-String", humanReadable: string, bytesCount: uStringPosition.length, translationType: .utf16String)
        } else {
            translation = Translation(definition: "Unable to decode", humanReadable: "🙅‍♂️ Invalid UTF16 String", bytesCount: uStringPosition.length, translationType: .utf16String)
        }
        return translation
    }
    
}
