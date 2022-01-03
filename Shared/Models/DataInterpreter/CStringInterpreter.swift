//
//  CStringInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

class CStringInterpreter: BaseInterpreter<[CStringInterpreter.InterpretedString]> {
    
    override var shouldPreload: Bool { true }
    
    struct InterpretedString {
        let value: String?
        let range: Range<Int>
    }
    
    override func generatePayload() -> [InterpretedString] {
        let rawData = self.data.raw
        var interpretedStrings: [InterpretedString] = []
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
            
            let interpreted = InterpretedString(value: String(data: nextCStringRawData, encoding: .utf8),
                              range: nextCStringStartIndex..<nextCStringStartIndex+nextCStringDataLength)
            
            interpretedStrings.append(interpreted)
            indexOfLastNull = indexOfCurNull
        }
        
        return interpretedStrings
    }
 
    override func numberOfTransSections() -> Int {
        return self.payload.count
    }
    
    override func transSection(at index: Int) -> TransSection {
        let interpreted = self.payload[index]
        let stringLength = interpreted.range.upperBound - interpreted.range.lowerBound
        let section = TransSection(baseIndex: self.data.startIndex + interpreted.range.lowerBound)
        if let string = interpreted.value {
            section.translateNext(stringLength) {
                Readable(description: "UTF8 encoded string", explanation: string.replacingOccurrences(of: "\n", with: "\\n"))
            }
        } else {
            section.translateNext(stringLength) {
                Readable(description: "Invalid utf8 encoded", explanation: "🙅‍♂️ Invalid utf8 string")
            }
        }
        return section
    }
}
