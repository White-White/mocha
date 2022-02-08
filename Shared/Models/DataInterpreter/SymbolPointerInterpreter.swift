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
    let startIndexInIndirectSymbolTable: Int
    
    init(_ data: DataSlice, is64Bit: Bool,
         machoSearchSource: MachoSearchSource,
         sectionType: SectionType,
         startIndexInIndirectSymbolTable: Int) {
        let pointerSize = is64Bit ? 8 : 4
        self.pointerSize = pointerSize
        self.numberOfPointers = data.count / pointerSize // symbol pointer section's entry size is 4
        self.sectionType = sectionType
        self.startIndexInIndirectSymbolTable = startIndexInIndirectSymbolTable
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }
    
    override var numberOfTranslationItems: Int {
        return self.numberOfPointers
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let pointerRawValue = data.truncated(from: index * pointerSize, length: pointerSize).raw.UInt64
        let indirectSymbolTableIndex = index + startIndexInIndirectSymbolTable
        
        var symbolName: String?
        if let indirectSymbolTableEntry = machoSearchSource.entryInIndirectSymbolTable(at: indirectSymbolTableIndex),
           let symbolTableEntry = machoSearchSource.symbolInSymbolTable(at: indirectSymbolTableEntry.symbolTableIndex),
           let _symbolName = machoSearchSource.stringInStringTable(at: Int(symbolTableEntry.indexInStringTable)) {
            symbolName = _symbolName
        }
        
        var description = "Pointer Raw Value"
        if sectionType == .S_LAZY_SYMBOL_POINTERS {
            description += " (Stub offset)"
        } else if sectionType == .S_NON_LAZY_SYMBOL_POINTERS {
            description += " (To be fixed by dyld)"
        }
        
        return TranslationItem(sourceDataRange: data.absoluteRange(index * pointerSize, pointerSize),
                               content: TranslationItemContent(description: description,
                                                               explanation: pointerRawValue.hex,
                                                               extraDescription: "Symbol Name of the Corresponding Indirect Symbol Table Entry",
                                                               extraExplanation: symbolName))
    }
}
