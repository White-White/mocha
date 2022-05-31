//
//  FunctionStartsInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/25.
//

import Foundation

struct FunctionStart {
    let startOffset: Int
    let byteLength: Int
    let rawValue: Swift.UInt64
}

// a great description for function start section data format
// https://stackoverflow.com/questions/9602438/mach-o-file-lc-function-starts-load-command

class FunctionStartsInterpreter: BaseInterpreter<[FunctionStart]> {
    
    let textSegmentVirtualStartAddress: Swift.UInt64
    
    override init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource) {
        guard let textSegment = machoSearchSource.segmentCommand(withName: Constants.segmentNameTEXT) else { fatalError() /* unlikely */ }
        self.textSegmentVirtualStartAddress = textSegment.vmaddr
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }
    
    override func generatePayload() -> [FunctionStart] {
        let rawData = self.data.raw
        // ref: https://opensource.apple.com/source/ld64/ld64-127.2/src/other/dyldinfo.cpp in function printFunctionStartsInfo
        // The code below decode (unsigned) LEB128 data into integers
        var functionStarts: [FunctionStart] = []
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
                    functionStarts.append(FunctionStart(startOffset: startIndex, byteLength: index - startIndex, rawValue: address))
                    more = false
                }
            } while (more)
        }
        return functionStarts
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.count
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let index = indexPath.section
        let functionStart = self.payload[index]
        
        var symbolName: String?
        if let functionSymbol = self.machoSearchSource.symbolInSymbolTable(by: functionStart.rawValue + textSegmentVirtualStartAddress),
           let _symbolName = self.machoSearchSource.stringInStringTable(at: Int(functionSymbol.indexInStringTable)) {
            symbolName = _symbolName
        }
        
        return TranslationItem(sourceDataRange: data.absoluteRange(functionStart.startOffset, functionStart.byteLength),
                               content: TranslationItemContent(description: "Address", explanation: functionStart.rawValue.hex,
                                                               extraDescription: "Referred Symbol Name", extraExplanation: symbolName,
                                                               hasDivider: true))
    }
    
}
