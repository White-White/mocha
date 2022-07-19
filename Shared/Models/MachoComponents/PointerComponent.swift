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
    
    init(_ data: Data, is64Bit: Bool, title: String) {
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
        
        super.init(data, title: title)
    }
    
}

class LiteralPointerComponent: PointerComponent {
    
    override func createTranslations() -> [Translation] {
        return self.pointerValues.map { self.translation(for: $0) }
    }
    
    func translation(for pointerValue: UInt64) -> Translation {
        guard let searchedString = (macho?.cStringSectionComponents.reduce(nil) { partialResult, component in
            partialResult ?? component.findString(virtualAddress: pointerValue)
        }) else {
            fatalError()
        }
        
        let translation = Translation(definition: "Pointer Value (Virtual Address)",
                                      humanReadable: pointerValue.hex,
                                      bytesCount: self.pointerSize, translationType: .number,
                                      extraDefinition: "Referenced String Symbol",
                                      extraHumanReadable: searchedString)
        return translation
    }
    
}

class SymbolPointerComponent: PointerComponent {
    
    override var initDependencies: [MachoComponent?] { [macho?.indirectSymbolTable, macho?.symbolTable] }
    let sectionType: SectionType
    let startIndexInIndirectSymbolTable: Int
    
    init(_ data: Data, is64Bit: Bool, title: String, sectionHeader: SectionHeader) {
        self.sectionType = sectionHeader.sectionType
        self.startIndexInIndirectSymbolTable = Int(sectionHeader.reserved1)
        super.init(data, is64Bit: is64Bit, title: title)
    }
    
    override func createTranslations() -> [Translation] {
        return self.pointerValues.enumerated().map { (index, pointerValue) in self.translation(for: pointerValue, index: index) }
    }
    
    func translation(for pointerValue: UInt64, index: Int) -> Translation {
        let indirectSymbolTableIndex = index + startIndexInIndirectSymbolTable
        
        var symbolName: String?
        if let indirectSymbolTableEntry = macho?.indirectSymbolTable?.findIndirectSymbol(atIndex: indirectSymbolTableIndex) {
            if indirectSymbolTableEntry.isSymbolLocal || indirectSymbolTableEntry.isSymbolAbsolute {
                symbolName = "Local Symbol. Absolute: \(indirectSymbolTableEntry.isSymbolAbsolute)"
            } else {
                symbolName = macho?.symbolTable?.findSymbol(atIndex: Int(indirectSymbolTableEntry.symbolTableIndex)).symbolName
            }
        }
        
        var description = "Pointer Raw Value"
        if sectionType == .S_LAZY_SYMBOL_POINTERS {
            description += " (Stub offset)"
        } else if sectionType == .S_NON_LAZY_SYMBOL_POINTERS {
            description += " (To be fixed by dyld)"
        }
        
        let translation = Translation(definition: description,
                                      humanReadable: pointerValue.hex,
                                      bytesCount: self.pointerSize, translationType: .number,
                                      extraDefinition: "Symbol Name of the Corresponding Indirect Symbol Table Entry",
                                      extraHumanReadable: symbolName)
        
        return translation
    }
    
}
