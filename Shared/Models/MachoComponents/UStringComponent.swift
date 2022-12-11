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

class UStringComponent: MachoComponent {
    
    private(set) var uStringPositions: [UStringPosition] = []
    
    override func runInitializing() {
        let dataLength = data.count
        let utf16UnitCount = dataLength / 2
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
            self.uStringPositions.append(uStringPosition)
            indexOfLastNull = curNullIndex
            
            self.initProgress.updateProgressForInitialize(finishedItems: index, total: utf16UnitCount)
        }
    }
    
    override func runTranslating() -> [TranslationGroup] {
        var translations: [GeneralTranslation] = []
        for (index, uStringPosition) in self.uStringPositions.enumerated() {
            var translation: GeneralTranslation
            if let string = String(data: self.data.subSequence(from: uStringPosition.relativeStartOffset, count: uStringPosition.length), encoding: .utf16LittleEndian) {
                translation = GeneralTranslation(definition: "UTF16-String", humanReadable: string, bytesCount: uStringPosition.length, translationType: .utf16String)
            } else {
                translation = GeneralTranslation(definition: "Unable to decode", humanReadable: "🙅‍♂️ Invalid UTF16 String", bytesCount: uStringPosition.length, translationType: .utf16String)
            }
            translations.append(translation)
            self.initProgress.updateProgressForTranslationInitialize(finishedItems: index, total: self.uStringPositions.count)
        }
        return [translations]
    }

}
