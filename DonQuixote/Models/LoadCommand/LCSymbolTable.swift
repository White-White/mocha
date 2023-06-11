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
    
}
