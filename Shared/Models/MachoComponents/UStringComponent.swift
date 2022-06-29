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

class UStringComponent: MachoLazyComponent<[UStringPosition]> {
    
    override var shouldPreload: Bool { true }
    
    override func generatePayload() -> [UStringPosition] {
        let rawData = self.dataSlice.raw
        let dataLength = rawData.count
        let utf16UnitCount = dataLength / 2
        var uStringPositions: [UStringPosition] = []
        var indexOfLastNull = -2
        for index in 0..<utf16UnitCount {
            let curNullIndex = index * 2
            let utf16UnitValue = rawData.select(from: curNullIndex, length: 2).UInt16
            if utf16UnitValue != 0 { continue }
            
            let uStringStartIndex = indexOfLastNull + 2
            let uStringDataLength = curNullIndex - uStringStartIndex
            if uStringDataLength == 0 { continue }
            
            let uStringPosition = UStringPosition(relativeStartOffset: uStringStartIndex,
                                                  length: uStringDataLength)
            uStringPositions.append(uStringPosition)
            indexOfLastNull = curNullIndex
        }
        return uStringPositions
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.count
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let index = indexPath.section
        let uStringPosition = self.payload[index]
        let uStringRelativeRange = uStringPosition.relativeStartOffset..<uStringPosition.relativeStartOffset+uStringPosition.length
        let uStringAbsoluteRange = self.dataSlice.absoluteRange(uStringRelativeRange)
        let uStringRaw = self.dataSlice.truncated(from: uStringPosition.relativeStartOffset, length: uStringPosition.length).raw
        
        if let string = String(data: uStringRaw, encoding: .utf16LittleEndian) {
            return TranslationItem(sourceDataRange: uStringAbsoluteRange,
                                   content: TranslationItemContent(description: "UTF16-String", explanation: string))
        } else {
            return TranslationItem(sourceDataRange: uStringAbsoluteRange,
                                   content: TranslationItemContent(description: "Unable to decode", explanation: "🙅‍♂️ Invalid UTF16 String"))
        }
    }
}
