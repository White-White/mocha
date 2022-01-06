//
//  CStringInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

struct CStringRawData {
    let data: Data
    let range: Range<Int>
}


class CStringInterpreter: BaseInterpreter<[CStringRawData]> {
    
    override var shouldPreload: Bool { true }
    
    let demanglingCString: Bool
    
    required init(_ data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey : Any]? = nil) {
        self.demanglingCString = (settings?[.shouldDemangleCString] as? Bool) ?? false
        super.init(data, is64Bit: is64Bit, settings: settings)
    }
    
    override func generatePayload() -> [CStringRawData] {
        let rawData = self.data.raw
        var cStringRaws: [CStringRawData] = []
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
            let nextCStringRawData = rawData.select(from: nextCStringStartIndex, length: nextCStringDataLength)
            
            let cStringRaw = CStringRawData(data: nextCStringRawData,
                                            range: nextCStringStartIndex..<nextCStringStartIndex+nextCStringDataLength)
            
            cStringRaws.append(cStringRaw)
            indexOfLastNull = indexOfCurNull
        }
        
        return cStringRaws
    }
 
    override func numberOfTransSections() -> Int {
        return self.payload.count
    }
    
    override func transSection(at index: Int) -> TransSection {
        let cStringRaw = self.payload[index]
        let stringLength = cStringRaw.range.upperBound - cStringRaw.range.lowerBound
        let section = TransSection(baseIndex: self.data.startIndex + cStringRaw.range.lowerBound)
        if let string = cStringRaw.data.utf8String {
            let explanation: String = string.replacingOccurrences(of: "\n", with: "\\n")
            let demangledCString: String? = self.demanglingCString ? swift_demangle(explanation) : nil
            section.translateNext(stringLength) {
                Readable(description: "UTF8 encoded string", explanation: explanation, extraExplanation: demangledCString)
            }
        } else {
            section.translateNext(stringLength) {
                Readable(description: "Invalid utf8 encoded", explanation: "🙅‍♂️ Invalid utf8 string")
            }
        }
        return section
    }
}

// MARK: Search In String Table

extension CStringInterpreter {
    
    struct StringTableSearched {
        let value: String?
        let demangled: String?
    }
    
    func findString(at stringTableByteIndex: Int) -> StringTableSearched? {
        for interpretedString in self.payload {
            if interpretedString.range.lowerBound == stringTableByteIndex, let stringValue = interpretedString.data.utf8String {
                return StringTableSearched(value: stringValue,
                                           demangled: self.demanglingCString ? swift_demangle(stringValue) : nil)
            }
        }
        return nil
    }
    
}
