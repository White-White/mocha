//
//  CStringInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

struct CStringPosition {
    let relativeStartOffset: Int
    let relativeVirtualAddress: Int
    let length: Int
}


class CStringInterpreter: BaseInterpreter<[CStringPosition]> {
    
    override var shouldPreload: Bool { true }
    var demanglingCString: Bool = false
    var componentStartVMAddr: Int = 0
    
    required init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource?) {
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }
    
    override func generatePayload() -> [CStringPosition] {
        let rawData = self.data.raw
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
            
            let cStringPosition = CStringPosition(relativeStartOffset: nextCStringStartIndex,
                                                  relativeVirtualAddress: nextCStringStartIndex + componentStartVMAddr,
                                                  length: nextCStringDataLength)
            cStringPositions.append(cStringPosition)
            indexOfLastNull = indexOfCurNull
        }
        
        return cStringPositions
    }
    
    override var numberOfTranslationItems: Int {
        return self.payload.count
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let cStringPosition = self.payload[index]
        let cStringRelativeRange = cStringPosition.relativeStartOffset..<cStringPosition.relativeStartOffset+cStringPosition.length
        let cStringAbsoluteRange = self.data.absoluteRange(cStringRelativeRange)
        let cStringRaw = self.data.truncated(from: cStringPosition.relativeStartOffset, length: cStringPosition.length).raw
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

extension CStringInterpreter {
    
    struct StringTableSearched {
        let value: String?
        let demangled: String?
    }
    
    func findString(at stringTableByteIndex: Int) -> StringTableSearched? {
        for cStringPosition in self.payload {
            if cStringPosition.relativeStartOffset == stringTableByteIndex,
               let stringValue = self.data.truncated(from: cStringPosition.relativeStartOffset, length: cStringPosition.length).raw.utf8String {
                return StringTableSearched(value: stringValue,
                                           demangled: self.demanglingCString ? swift_demangle(stringValue) : nil)
            }
        }
        return nil
    }
    
    func findString(by relativeVirtualAddress: Int) -> StringTableSearched? {
        for cStringPosition in self.payload {
            if cStringPosition.relativeVirtualAddress == relativeVirtualAddress,
               let stringValue = self.data.truncated(from: cStringPosition.relativeStartOffset, length: cStringPosition.length).raw.utf8String {
                return StringTableSearched(value: stringValue, demangled: nil)
            }
        }
        return nil
    }
}
