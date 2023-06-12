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
    
    override var commandTranslations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(definition: "Symbol table offset", humanReadable: self.symbolTableOffset.hex, translationType: .uint32))
        translations.append(Translation(definition: "Number of entries", humanReadable: "\(self.numberOfSymbolTableEntries)", translationType: .uint32))
        translations.append(Translation(definition: "String table offset", humanReadable: self.stringTableOffset.hex, translationType: .uint32))
        translations.append(Translation(definition: "Size of string table", humanReadable: self.sizeOfStringTable.hex, translationType: .uint32))
        return translations
    }
    
}
