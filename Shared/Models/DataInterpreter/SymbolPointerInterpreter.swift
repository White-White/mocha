//
//  SymbolPointerInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/3.
//

import Foundation

struct DummySymbolPointer { }

class SymbolPointerInterpreter: BaseInterpreter<[DummySymbolPointer]> {
    
    let numberOfPointers: Int
    let pointerSize: Int
    let sectionType: SectionType
    
    init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource, sectionType: SectionType) {
        let pointerSize = is64Bit ? 8 : 4
        self.pointerSize = pointerSize
        self.numberOfPointers = data.count / pointerSize // symbol pointer section's entry size is 4
        self.sectionType = sectionType
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }
    
    override var numberOfTranslationItems: Int {
        return self.numberOfPointers
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let pointerRawValue = data.truncated(from: index * pointerSize, length: pointerSize).raw.UInt64
        return TranslationItem(sourceDataRange: data.absoluteRange(index * pointerSize, pointerSize),
                               content: TranslationItemContent(description: "Pointer", explanation: pointerRawValue.hex))
    }
}
