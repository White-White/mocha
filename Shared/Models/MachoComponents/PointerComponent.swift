//
//  PointerComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class PointerComponent: MachoComponent {
    
    let is64Bit: Bool
    let pointerSize: Int
    private(set) var pointerValues: [UInt64] = []
    
    init(_ data: Data, is64Bit: Bool, title: String) {
        self.is64Bit = is64Bit
        let pointerSize = is64Bit ? 8 : 4
        self.pointerSize = pointerSize
        /* section of type S_LITERAL_POINTERS should be in align of pointerSize */
        guard data.count % pointerSize == 0 else { fatalError() }
        super.init(data, title: title)
    }
    
    override func runInitializing() {
        var dataShifter = DataShifter(data)
        while dataShifter.shiftable {
            let pointerData = dataShifter.shift(.rawNumber(self.pointerSize))
            self.pointerValues.append(self.is64Bit ? pointerData.UInt64 : UInt64(pointerData.UInt32))
        }
    }
    
    override func runTranslating() -> [TranslationGroup] {
        [self.pointerValues.enumerated().map { (index, pointerValue) in self.translation(for: pointerValue, index: index) }]
    }
    
    func translation(for pointerValue: UInt64, index: Int) -> GeneralTranslation {
        fatalError()
    }
    
}

class LiteralPointerComponent: PointerComponent {
    
    private var allCStringComponents: [CStringSectionComponent] = []
    
    override var macho: Macho? {
        didSet {
            if let allCStringComponents = macho?.cStringSectionComponents {
                allCStringComponents.forEach { $0.addChildComponent(self) }
                self.allCStringComponents = allCStringComponents
            }
        }
    }
    
    override func translation(for pointerValue: UInt64, index: Int) -> GeneralTranslation {
        let searchedString = (self.allCStringComponents.reduce(nil) { partialResult, component in
            partialResult ?? component.findString(virtualAddress: pointerValue)
        })
        
        let translation = GeneralTranslation(definition: "Pointer Value (Virtual Address)",
                                      humanReadable: pointerValue.hex,
                                      bytesCount: self.pointerSize, translationType: self.is64Bit ? .uint64 : .uint32,
                                      extraDefinition: "Referenced String Symbol",
                                      extraHumanReadable: searchedString)
        return translation
    }
    
    
}

class SymbolPointerComponent: PointerComponent {

    override var macho: Macho? {
        didSet {
            guard let indirectSymbolTable = self.macho?.indirectSymbolTable else { fatalError() }
            indirectSymbolTable.addChildComponent(self)
        }
    }
    
    let sectionType: SectionType
    let startIndexInIndirectSymbolTable: Int
    
    init(_ data: Data, is64Bit: Bool, title: String, sectionHeader: SectionHeader) {
        self.sectionType = sectionHeader.sectionType
        self.startIndexInIndirectSymbolTable = Int(sectionHeader.reserved1)
        super.init(data, is64Bit: is64Bit, title: title)
    }
    
    override func translation(for pointerValue: UInt64, index: Int) -> GeneralTranslation {
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
        
        let translation = GeneralTranslation(definition: description,
                                      humanReadable: pointerValue.hex,
                                      bytesCount: self.pointerSize, translationType: self.is64Bit ? .uint64 : .uint32,
                                      extraDefinition: "Symbol Name of the Corresponding Indirect Symbol Table Entry",
                                      extraHumanReadable: symbolName)
        
        return translation
    }
    
}
