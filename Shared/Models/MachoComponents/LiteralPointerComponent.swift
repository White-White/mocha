//
//  LiteralPointerComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/20.
//

import Foundation

struct LiteralPointer {
    let relativeDataOffset: Int
    let pointerValue: Swift.UInt64
}

class LiteralPointerComponent: MachoLazyComponent<[LiteralPointer]> {
    
    let pointerLength: Int
    
    override init(_ data: Data, macho: Macho, is64Bit: Bool, title: String, subTitle: String?) {
        self.pointerLength = is64Bit ? 8 : 4
        super.init(data, macho: macho, is64Bit: is64Bit, title: title, subTitle: subTitle)
    }
    
    override func generatePayload() -> [LiteralPointer] {
        let rawData = self.data
        guard rawData.count % pointerLength == 0 else { fatalError() /* section of type S_LITERAL_POINTERS should be in align of 8 (bytes) */  }
        var pointers: [LiteralPointer] = []
        let numberOfPointers = rawData.count / 8
        for index in 0..<numberOfPointers {
            let relativeDataOffset = index * pointerLength
            let pointerRawData = rawData.select(from: relativeDataOffset, length: pointerLength)
            let pointer = LiteralPointer(relativeDataOffset: relativeDataOffset,
                                         pointerValue: is64Bit ? pointerRawData.UInt64 : UInt64(pointerRawData.UInt32))
            pointers.append(pointer)
        }
        return pointers
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.count
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let index = indexPath.section
        let pointer = self.payload[index]
        guard let searchedString = self.macho.searchString(by: pointer.pointerValue) else {
            // didn't find string
            fatalError()
        }
        return TranslationItem(sourceDataRange: self.data.absoluteRange(pointer.relativeDataOffset, self.pointerLength),
                               content: TranslationItemContent(description: "Pointer Value (Virtual Address)",
                                                               explanation: pointer.pointerValue.hex,
                                                               extraDescription: "Referenced String Symbol",
                                                               extraExplanation: searchedString,
                                                               hasDivider: true))
    }
}
