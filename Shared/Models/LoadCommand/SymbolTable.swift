//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class SymbolTable: LoadCommand {
    
    let symbolTableOffset: UInt32
    let numberOfSymbolTableEntries: UInt32
    let stringTableOffset: UInt32
    let sizeOfStringTable: UInt32
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        self.symbolTableOffset = itemsContainer.translate(next: .doubleWords,
                                                          dataInterpreter: DataInterpreterPreset.UInt32,
                                                          itemContentGenerator: { value in TranslationItemContent(description: "Symbol table offset", explanation: value.hex) })
        
        self.numberOfSymbolTableEntries = itemsContainer.translate(next: .doubleWords,
                                                                   dataInterpreter: DataInterpreterPreset.UInt32,
                                                                   itemContentGenerator: { value in TranslationItemContent(description: "Number of entries", explanation: "\(value)") })
        
        self.stringTableOffset = itemsContainer.translate(next: .doubleWords,
                                                          dataInterpreter: DataInterpreterPreset.UInt32,
                                                          itemContentGenerator: { value in TranslationItemContent(description: "String table offset", explanation: value.hex) })
        
        self.sizeOfStringTable = itemsContainer.translate(next: .doubleWords,
                                                          dataInterpreter: DataInterpreterPreset.UInt32,
                                                          itemContentGenerator: { value in TranslationItemContent(description: "Size of string table", explanation: value.hex) })
        
        super.init(with: type, data: data, itemsContainer: itemsContainer)
    }
}

class DynamicSymbolTable: LoadCommand {
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
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        self.ilocalsym =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "index to local symbols ", explanation: "\(value)") })
        
        self.nlocalsym =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of local symbols ", explanation: "\(value)") })
        
        self.iextdefsym =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "index to externally defined symbols ", explanation: "\(value)") })
        
        self.nextdefsym =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of externally defined symbols ", explanation: "\(value)") })
        
        self.iundefsym =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "index to undefined symbols ", explanation: "\(value)") })
        
        self.nundefsym =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of undefined symbols ", explanation: "\(value)") })
        
        self.tocoff =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "file offset to table of contents ", explanation: "\(value.hex)") })
        
        self.ntoc =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of entries in table of contents ", explanation: "\(value)") })
        
        self.modtaboff =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "file offset to module table ", explanation: "\(value.hex)") })
        
        self.nmodtab =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of module table entries ", explanation: "\(value)") })
        
        self.extrefsymoff =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "offset to referenced symbol table ", explanation: "\(value.hex)") })
        
        self.nextrefsyms =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of referenced symbol table entries ", explanation: "\(value)") })
        
        self.indirectsymoff =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "file offset to the indirect symbol table ", explanation: "\(value.hex)") })
        
        self.nindirectsyms =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of indirect symbol table entries ", explanation: "\(value)") })
        
        self.extreloff =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "offset to external relocation entries ", explanation: "\(value.hex)") })
        
        self.nextrel =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of external relocation entries ", explanation: "\(value)") })
        
        self.locreloff =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "offset to local relocation entries ", explanation: "\(value.hex)") })
        
        self.nlocrel =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "number of local relocation entries ", explanation: "\(value)") })
        
        
        super.init(with: type, data: data, itemsContainer: itemsContainer)
    }
    
}
