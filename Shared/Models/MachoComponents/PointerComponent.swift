//
//  PointerComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class PointerComponent: MachoComponent {
    
    let pointerSize: Int
    let pointerValues: [UInt64]
    
    init(_ data: Data, is64Bit: Bool, title: String, subTitle: String) {
        let pointerSize = is64Bit ? 8 : 4
        self.pointerSize = pointerSize
        
        /* section of type S_LITERAL_POINTERS should be in align of pointerSize */
        guard data.count % pointerSize == 0 else { fatalError() }
        
        var pointerValues: [UInt64] = []
        var dataShifter = DataShifter(data)
        while dataShifter.shiftable {
            let pointerData = dataShifter.shift(.rawNumber(pointerSize))
            pointerValues.append(is64Bit ? pointerData.UInt64 : UInt64(pointerData.UInt32))
        }
        self.pointerValues = pointerValues
        
        super.init(data, title: title, subTitle: subTitle)
    }
    
}

class LiteralPointerComponent: PointerComponent {
    
    override func createTranslations() -> [Translation] {
        return self.pointerValues.map { self.translation(for: $0) }
    }

    func translation(for pointerValue: UInt64) -> Translation {
        guard let searchedString = (macho?.allCStringComponents.reduce(nil) { partialResult, component in
            partialResult ?? component.findString(virtualAddress: pointerValue)
        }) else {
            fatalError()
        }
        
        let translation = Translation(description: "Pointer Value (Virtual Address)",
                                      explanation: pointerValue.hex,
                                      bytesCount: self.pointerSize,
                                      extraDescription: "Referenced String Symbol",
                                      extraExplanation: searchedString,
                                      hasDivider: true)
        return translation
    }
    
}

class SymbolPointerComponent: PointerComponent {
    
    let sectionType: SectionType
    let startIndexInIndirectSymbolTable: Int

    init(_ data: Data, is64Bit: Bool, title: String, subTitle: String, sectionHeader: SectionHeader) {
        self.sectionType = sectionHeader.sectionType
        self.startIndexInIndirectSymbolTable = Int(sectionHeader.reserved1)
        super.init(data, is64Bit: is64Bit, title: title, subTitle: subTitle)
    }
    
    override func createTranslations() -> [Translation] {
        return self.pointerValues.enumerated().map { (index, pointerValue) in self.translation(for: pointerValue, index: index) }
    }
    
    func translation(for pointerValue: UInt64, index: Int) -> Translation {
        let indirectSymbolTableIndex = index + startIndexInIndirectSymbolTable
        var symbolName: String?
        if let indirectSymbolTableEntry = macho?.indirectSymbolTable?.indirectSymbol(atIndex: indirectSymbolTableIndex),
           let symbolTableEntry = macho?.symbolTable?.symbol(atIndex: Int(indirectSymbolTableEntry.symbolTableIndex)),
           let _symbolName = macho?.stringTable?.findString(at: Int(symbolTableEntry.indexInStringTable)) {
            symbolName = _symbolName
        }
        
        var description = "Pointer Raw Value"
        if sectionType == .S_LAZY_SYMBOL_POINTERS {
            description += " (Stub offset)"
        } else if sectionType == .S_NON_LAZY_SYMBOL_POINTERS {
            description += " (To be fixed by dyld)"
        }
        
        let translation = Translation(description: description,
                                      explanation: pointerValue.hex,
                                      bytesCount: self.pointerSize,
                                      extraDescription: "Symbol Name of the Corresponding Indirect Symbol Table Entry",
                                      extraExplanation: symbolName)
        
        return translation
    }
    
}
