//
//  PointerComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class PointerComponent: MachoBaseElement {
    
    let is64Bit: Bool
    let pointerSize: Int
    private(set) var pointerValues: [UInt64] = []
    
    init(_ data: Data, is64Bit: Bool, title: String) {
        self.is64Bit = is64Bit
        let pointerSize = is64Bit ? 8 : 4
        self.pointerSize = pointerSize
        /* section of type S_LITERAL_POINTERS should be in align of pointerSize */
        guard data.count % pointerSize == 0 else { fatalError() }
        super.init(data, title: title, subTitle: nil)
    }
    
    override func loadTranslations() async {
        var dataShifter = DataShifter(data)
        while dataShifter.shiftable {
            let pointerData = dataShifter.shift(.rawNumber(self.pointerSize))
            self.pointerValues.append(self.is64Bit ? pointerData.UInt64 : UInt64(pointerData.UInt32))
        }
        
        let translations = await withTaskGroup(of: Translation.self, body: { taskGroup in
            for (index, pointerValue) in self.pointerValues.enumerated() {
                taskGroup.addTask {
                    await self.translation(for: pointerValue, index: index)
                }
            }
            return await taskGroup.reduce(into: [Translation]()) { partialResult, translation in
                partialResult.append(translation)
            }
        })
        await save(translations: translations)
    }
    
    
    func translation(for pointerValue: UInt64, index: Int) async -> Translation {
        fatalError()
    }
    
}

class LiteralPointerComponent: PointerComponent {
    
    let allCStringSections: [CStringSection]
    
    init(allCStringSections: [CStringSection], data: Data, is64Bit: Bool, title: String) {
        self.allCStringSections = allCStringSections
        super.init(data, is64Bit: is64Bit, title: title)
    }
    
    override func translation(for pointerValue: UInt64, index: Int) async -> Translation {
        var searchedString: String?
        for cStringSection in allCStringSections {
            if let finded = await cStringSection.findString(virtualAddress: pointerValue) {
                searchedString = finded
                break
            }
        }
        
        let translation = Translation(definition: "Pointer Value (Virtual Address)",
                                      humanReadable: pointerValue.hex,
                                      translationType: self.is64Bit ? .uint64 : .uint32,
                                      extraDefinition: "Referenced String Symbol",
                                      extraHumanReadable: searchedString)
        return translation
    }
    
    
}

class SymbolPointerComponent: PointerComponent {

    let sectionType: SectionType
    let startIndexInIndirectSymbolTable: Int
    let indirectSymbolTable: IndirectSymbolTable?
    
    init(indirectSymbolTable: IndirectSymbolTable?, sectionHeader: SectionHeader, data: Data, is64Bit: Bool, title: String) {
        self.sectionType = sectionHeader.sectionType
        self.startIndexInIndirectSymbolTable = Int(sectionHeader.reserved1)
        self.indirectSymbolTable = indirectSymbolTable
        super.init(data, is64Bit: is64Bit, title: title)
    }
    
    override func translation(for pointerValue: UInt64, index: Int) async -> Translation {
        
        let indirectSymbolTableIndex = index + startIndexInIndirectSymbolTable
        
        var symbolName: String?
        // TODO: FIXME:
        //        if let indirectSymbolTableEntry = macho?.indirectSymbolTable?.findIndirectSymbol(atIndex: indirectSymbolTableIndex) {
        //            if indirectSymbolTableEntry.isSymbolLocal || indirectSymbolTableEntry.isSymbolAbsolute {
        //                symbolName = "Local Symbol. Absolute: \(indirectSymbolTableEntry.isSymbolAbsolute)"
        //            } else {
        //                symbolName = macho?.symbolTable?.findSymbol(atIndex: Int(indirectSymbolTableEntry.symbolTableIndex)).symbolName
        //            }
        //        }
        
        var description = "Pointer Raw Value"
        if sectionType == .S_LAZY_SYMBOL_POINTERS {
            description += " (Stub offset)"
        } else if sectionType == .S_NON_LAZY_SYMBOL_POINTERS {
            description += " (To be fixed by dyld)"
        }
        
        let translation = Translation(definition: description,
                                             humanReadable: pointerValue.hex,
                                             translationType: self.is64Bit ? .uint64 : .uint32,
                                             extraDefinition: "Symbol Name of the Corresponding Indirect Symbol Table Entry",
                                             extraHumanReadable: symbolName)
        
        return translation
    }
    
}
