//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LCSymbolTable: LoadCommand, TranslatorContainerGenerator {
    
    let symbolTableOffset: UInt32
    let numberOfSymbolTableEntries: UInt32
    let stringTableOffset: UInt32
    let sizeOfStringTable: UInt32
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        var shifter = DataShifter(loadCommandData)
        _ = shifter.nextQuadWord() // skip basic data
        self.symbolTableOffset = shifter.nextDoubleWord().UInt32
        self.numberOfSymbolTableEntries = shifter.nextDoubleWord().UInt32
        self.stringTableOffset = shifter.nextDoubleWord().UInt32
        self.sizeOfStringTable = shifter.nextDoubleWord().UInt32
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "Symbol table offset", explanation: "\(self.symbolTableOffset.hex)") }
        section.translateNextDoubleWord { Readable(description: "Number of entries", explanation: "\(self.numberOfSymbolTableEntries)") }
        section.translateNextDoubleWord { Readable(description: "String table offset", explanation: "\(self.stringTableOffset.hex)") }
        section.translateNextDoubleWord { Readable(description: "Size of string table", explanation: self.sizeOfStringTable.hex) }
        return section
    }
    
    func makeTranslatorContainers(from machoData: SmartData, is64Bit: Bool) -> [TranslatorContainer] {
        
        let symbolTableStartOffset = Int(self.symbolTableOffset)
        let numberOfEntries = Int(self.numberOfSymbolTableEntries)
        let entrySize = is64Bit ? 16 : 12
        let symbolTableData = machoData.truncated(from: symbolTableStartOffset, length: numberOfEntries * entrySize)
        
        let stringTableStartOffset = Int(self.stringTableOffset)
        let stringTableSize = Int(self.sizeOfStringTable)
        let stringTableData = machoData.truncated(from: stringTableStartOffset, length: stringTableSize)
        
        let symbolTableTranslatorContainer = TranslatorContainer(symbolTableData,
                                                                 is64Bit: is64Bit,
                                                                 translatorType: ModelTranslator<SymbolTableEntryModel>.self,
                                                                 primaryName: "Symbol Table",
                                                                 secondaryName: "__LINKEDIT")
        
        let stringTableTranslatorContainer = TranslatorContainer(stringTableData,
                                                                 is64Bit: is64Bit,
                                                                 translatorType: CStringTranslator.self,
                                                                 primaryName: "String Table",
                                                                 secondaryName: "__LINKEDIT")
        
        return [symbolTableTranslatorContainer, stringTableTranslatorContainer]
    }
}

class LCDynamicSymbolTable: LoadCommand {
    let ilocalsym: UInt32       /* index to local symbols */
    let nlocalsym: UInt32       /* number of local symbols */
    
    let iextdefsym: UInt32      /* index to externally defined symbols */
    let nextdefsym: UInt32      /* number of externally defined symbols */
    
    let iundefsym: UInt32       /* index to undefined symbols */
    let nundefsym: UInt32       /* number of undefined symbols */
    
    let tocoff: UInt32          /* file offset to table of contents */
    let ntoc: UInt32            /* number of entries in table of contents */
    
    let modtaboff: UInt32       /* file offset to module table */
    let nmodtab: UInt32         /* number of module table entries */
    
    let extrefsymoff: UInt32    /* offset to referenced symbol table */
    let nextrefsyms: UInt32     /* number of referenced symbol table entries */
    
    let indirectsymoff: UInt32  /* file offset to the indirect symbol table */
    let nindirectsyms: UInt32   /* number of indirect symbol table entries */
    
    let extreloff: UInt32       /* offset to external relocation entries */
    let nextrel: UInt32         /* number of external relocation entries */
    
    let locreloff: UInt32       /* offset to local relocation entries */
    let nlocrel: UInt32         /* number of local relocation entries */
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        var shifter = DataShifter(loadCommandData)
        _ = shifter.nextQuadWord() // skip basic data
        self.ilocalsym = shifter.nextDoubleWord().UInt32
        self.nlocalsym = shifter.nextDoubleWord().UInt32
        self.iextdefsym = shifter.nextDoubleWord().UInt32
        self.nextdefsym = shifter.nextDoubleWord().UInt32
        self.iundefsym = shifter.nextDoubleWord().UInt32
        self.nundefsym = shifter.nextDoubleWord().UInt32
        self.tocoff = shifter.nextDoubleWord().UInt32
        self.ntoc = shifter.nextDoubleWord().UInt32
        self.modtaboff = shifter.nextDoubleWord().UInt32
        self.nmodtab = shifter.nextDoubleWord().UInt32
        self.extrefsymoff = shifter.nextDoubleWord().UInt32
        self.nextrefsyms = shifter.nextDoubleWord().UInt32
        self.indirectsymoff = shifter.nextDoubleWord().UInt32
        self.nindirectsyms = shifter.nextDoubleWord().UInt32
        self.extreloff = shifter.nextDoubleWord().UInt32
        self.nextrel = shifter.nextDoubleWord().UInt32
        self.locreloff = shifter.nextDoubleWord().UInt32
        self.nlocrel = shifter.nextDoubleWord().UInt32
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "index to local symbols ", explanation: "\(self.ilocalsym)") }
        section.translateNextDoubleWord { Readable(description: "number of local symbols ", explanation: "\(self.nlocalsym)") }
        section.translateNextDoubleWord { Readable(description: "index to externally defined symbols ", explanation: "\(self.iextdefsym)") }
        section.translateNextDoubleWord { Readable(description: "number of externally defined symbols ", explanation: "\(self.nextdefsym)") }
        section.translateNextDoubleWord { Readable(description: "index to undefined symbols ", explanation: "\(self.iundefsym)") }
        section.translateNextDoubleWord { Readable(description: "number of undefined symbols ", explanation: "\(self.nundefsym)") }
        section.translateNextDoubleWord { Readable(description: "file offset to table of contents ", explanation: "\(self.tocoff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of entries in table of contents ", explanation: "\(self.ntoc)") }
        section.translateNextDoubleWord { Readable(description: "file offset to module table ", explanation: "\(self.modtaboff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of module table entries ", explanation: "\(self.nmodtab)") }
        section.translateNextDoubleWord { Readable(description: "offset to referenced symbol table ", explanation: "\(self.extrefsymoff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of referenced symbol table entries ", explanation: "\(self.nextrefsyms)") }
        section.translateNextDoubleWord { Readable(description: "file offset to the indirect symbol table ", explanation: "\(self.indirectsymoff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of indirect symbol table entries ", explanation: "\(self.nindirectsyms)") }
        section.translateNextDoubleWord { Readable(description: "offset to external relocation entries ", explanation: "\(self.extreloff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of external relocation entries ", explanation: "\(self.nextrel)") }
        section.translateNextDoubleWord { Readable(description: "offset to local relocation entries ", explanation: "\(self.locreloff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of local relocation entries ", explanation: "\(self.nlocrel)") }
        return section
    }
}
