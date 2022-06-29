//
//  CStringInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

struct CStringPosition {
    let startOffset: Int
    let virtualAddress: Swift.UInt64
    let length: Int
}

class CStringComponent: MachoLazyComponent<[CStringPosition]> {
    
    override var shouldPreload: Bool { true }
    let demanglingCString: Bool
    let sectionVirtualAddress: UInt64
    
    init(_ dataSlice: DataSlice, macho: Macho, is64Bit: Bool, title: String, subTitle: String?, sectionVirtualAddress: UInt64, demanglingCString: Bool) {
        self.demanglingCString = demanglingCString
        self.sectionVirtualAddress = sectionVirtualAddress
        super.init(dataSlice, macho: macho, is64Bit: is64Bit, title: title, subTitle: subTitle)
    }
    
    override func generatePayload() -> [CStringPosition] {
        let rawData = self.dataSlice.raw
        var cStringPositions: [CStringPosition] = []
        var indexOfLastNull: Int? // index of last null char ( "\0" )
        
        for (indexOfCurNull, byte) in rawData.enumerated() {
            guard byte == 0 else { continue } // find null characters
            
            let lastIndex = indexOfLastNull ?? -1
            if indexOfCurNull - lastIndex == 1 {
                indexOfLastNull = indexOfCurNull // skip continuous \0
                continue
            }
            
            let nextCStringStartIndex = lastIndex + 1 // lastIdnex points to last null, ignore
            let nextCStringDataLength = indexOfCurNull - nextCStringStartIndex
            
            let cStringPosition = CStringPosition(startOffset: nextCStringStartIndex,
                                                  virtualAddress: Swift.UInt64(nextCStringStartIndex) + sectionVirtualAddress,
                                                  length: nextCStringDataLength)
            cStringPositions.append(cStringPosition)
            indexOfLastNull = indexOfCurNull
        }
        
        return cStringPositions
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.count
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let index = indexPath.section
        let cStringPosition = self.payload[index]
        let cStringRelativeRange = cStringPosition.startOffset..<cStringPosition.startOffset+cStringPosition.length
        let cStringAbsoluteRange = self.dataSlice.absoluteRange(cStringRelativeRange)
        let cStringRaw = self.dataSlice.truncated(from: cStringPosition.startOffset, length: cStringPosition.length).raw
        if let string = cStringRaw.utf8String {
            let explanation: String = string.replacingOccurrences(of: "\n", with: "\\n")
            let demangledCString: String? = self.demanglingCString ? swift_demangle(explanation) : nil
            return TranslationItem(sourceDataRange: cStringAbsoluteRange,
                                   content: TranslationItemContent(description: "UTF8-String", explanation: explanation, extraExplanation: demangledCString))
        } else {
            return TranslationItem(sourceDataRange: cStringAbsoluteRange,
                                   content: TranslationItemContent(description: "Unable to decode", explanation: "🙅‍♂️ Invalid UTF8 String"))
        }
    }
}

// MARK: Search In String Table

extension CStringComponent {
    
    func findString(at offset: Int) -> String? {
        let rawData = self.dataSlice.raw
        for index in offset..<rawData.count {
            let byte = rawData[rawData.startIndex+index]
            if byte != 0 { continue }
            let length = index - offset + 1
            return self.dataSlice.truncated(from: offset, length: length).raw.utf8String
        }
        return nil
    }
    
    func findString(with virtualAddress: Swift.UInt64) -> String? {
        for cStringPosition in self.payload {
            if cStringPosition.virtualAddress == virtualAddress {
                return self.dataSlice.truncated(from: cStringPosition.startOffset, length: cStringPosition.length).raw.utf8String
            }
        }
        return nil
    }
}
