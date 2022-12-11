//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LCSymbolTable: LoadCommand {
    
    let symbolTableOffset: UInt32
    let numberOfSymbolTableEntries: UInt32
    let stringTableOffset: UInt32
    let sizeOfStringTable: UInt32
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.symbolTableOffset = dataShifter.shiftUInt32()
        self.numberOfSymbolTableEntries = dataShifter.shiftUInt32()
        self.stringTableOffset = dataShifter.shiftUInt32()
        self.sizeOfStringTable = dataShifter.shiftUInt32()
        super.init(data, type: type)
    }
    
    override var commandTranslations: [GeneralTranslation] {
        var translations: [GeneralTranslation] = []
        translations.append(GeneralTranslation(definition: "Symbol table offset", humanReadable: self.symbolTableOffset.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "Number of entries", humanReadable: "\(self.numberOfSymbolTableEntries)", bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "String table offset", humanReadable: self.stringTableOffset.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "Size of string table", humanReadable: self.sizeOfStringTable.hex, bytesCount: 4, translationType: .uint32))
        return translations
    }
    
    func symbolTable(machoData: Data, machoHeader: MachoHeader) -> SymbolTable {
        let is64Bit = machoHeader.is64Bit
        let symbolTableStartOffset = Int(self.symbolTableOffset)
        let numberOfEntries = Int(self.numberOfSymbolTableEntries)
        let entrySize = is64Bit ? 16 : 12
        let symbolTableData = machoData.subSequence(from: symbolTableStartOffset, count: numberOfEntries * entrySize)
        return SymbolTable(symbolTableData, title: "Symbol Table", is64Bit: is64Bit)
    }
    
    func stringTable(machoData: Data) -> StringTable {
        let stringTableStartOffset = Int(self.stringTableOffset)
        let stringTableSize = Int(self.sizeOfStringTable)
        let stringTableData = machoData.subSequence(from: stringTableStartOffset, count: stringTableSize)
        return StringTable(stringTableData, title: "String Table")
    }
    
}
