//
//  ULEB128Interpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

// to known more about LEB128 encoding, see https://en.wikipedia.org/wiki/LEB128

class ULEB128Interpreter: BaseInterpreter<[ULEB128Interpreter.DecodedInteger]> {
    
    struct DecodedInteger {
        let value: UInt64
        let range: Range<Int>
    }
    
    override func generatePayload() -> [DecodedInteger] {
        let rawData = self.data.raw
        // ref: https://opensource.apple.com/source/ld64/ld64-127.2/src/other/dyldinfo.cpp in function printFunctionStartsInfo
        // The code below decode (unsigned) LEB128 data into integers
        var resultAddresses: [DecodedInteger] = []
        var address: UInt64 = 0
        var index = 0
        while index < rawData.count {
            var delta: Swift.UInt64 = 0
            var shift: Swift.UInt32 = 0
            var more = true
            
            let startIndex = index
            repeat {
                let byte = rawData[rawData.startIndex+index]; index += 1
                delta |= ((Swift.UInt64(byte) & 0x7f) << shift)
                shift += 7
                if byte < 0x80 {
                    address += delta
                    resultAddresses.append(DecodedInteger(value: address, range: startIndex..<index))
                    more = false
                }
            } while (more)
        }
        return resultAddresses
    }
    
    override var numberOfTranslationItems: Int {
        return self.payload.count
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let decoded = self.payload[index]
        return TranslationItem(sourceDataRange: data.absoluteRange(decoded.range.lowerBound, decoded.range.upperBound - decoded.range.lowerBound),
                               content: TranslationItemContent(description: "Address", explanation: "\(decoded.value.hex)"))
    }
}
