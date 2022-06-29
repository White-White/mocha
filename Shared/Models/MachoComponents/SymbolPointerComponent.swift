//
//  SymbolPointerComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/3.
//

import Foundation

struct DummySymbolPointer { }

class SymbolPointerComponent: MachoLazyComponent<[DummySymbolPointer]> {
    
    let numberOfPointers: Int
    let pointerSize: Int
    let sectionType: SectionType
    let startIndexInIndirectSymbolTable: Int
    
    init(_ dataSlice: DataSlice, macho: Macho, is64Bit: Bool, title: String, subTitle: String?, sectionType: SectionType, startIndexInIndirectSymbolTable: Int) {
        let pointerSize = is64Bit ? 8 : 4
        self.pointerSize = pointerSize
        self.numberOfPointers = dataSlice.count / pointerSize
        self.sectionType = sectionType
        self.startIndexInIndirectSymbolTable = startIndexInIndirectSymbolTable
        super.init(dataSlice, macho: macho, is64Bit: is64Bit, title: title, subTitle: subTitle)
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.numberOfPointers
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let index = indexPath.section
        let pointerRawData = dataSlice.truncated(from: index * pointerSize, length: pointerSize).raw
        let pointerRawValue = is64Bit ? pointerRawData.UInt64 : UInt64(pointerRawData.UInt32)
        let indirectSymbolTableIndex = index + startIndexInIndirectSymbolTable
        
        var symbolName: String?
        if let indirectSymbolTableEntry = macho.entryInIndirectSymbolTable(at: indirectSymbolTableIndex),
           let symbolTableEntry = macho.symbolInSymbolTable(at: indirectSymbolTableEntry.symbolTableIndex),
           let _symbolName = macho.stringInStringTable(at: Int(symbolTableEntry.indexInStringTable)) {
            symbolName = _symbolName
        }
        
        var description = "Pointer Raw Value"
        if sectionType == .S_LAZY_SYMBOL_POINTERS {
            description += " (Stub offset)"
        } else if sectionType == .S_NON_LAZY_SYMBOL_POINTERS {
            description += " (To be fixed by dyld)"
        }
        
        return TranslationItem(sourceDataRange: dataSlice.absoluteRange(index * pointerSize, pointerSize),
                               content: TranslationItemContent(description: description,
                                                               explanation: pointerRawValue.hex,
                                                               extraDescription: "Symbol Name of the Corresponding Indirect Symbol Table Entry",
                                                               extraExplanation: symbolName))
    }
}
