//
//  IndirectSymbolTableEntry.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/6.
//

import Foundation

struct IndirectSymbolTableEntry {
    
    let isSymbolLocal: Bool
    let isSymbolAbsolute: Bool
    let symbolTableIndex: UInt32
    let symbolTable: SymbolTable?
    
    init(with data: Data, is64Bit: Bool, symbolTable: SymbolTable?) {
        self.symbolTableIndex = data.UInt32
        self.symbolTable = symbolTable
        self.isSymbolLocal = self.symbolTableIndex & 0x80000000 != 0 // INDIRECT_SYMBOL_LOCAL
        self.isSymbolAbsolute = self.symbolTableIndex & 0x40000000 != 0 // INDIRECT_SYMBOL_ABS
    }
    
    func generateTranslations() async -> [GeneralTranslation] {
        if self.isSymbolLocal || self.isSymbolAbsolute {
            return [GeneralTranslation(definition: "Symbol Table Index", humanReadable: "\(self.symbolTableIndex.hex)",
                                bytesCount: 4, translationType: .uint32,
                                extraDefinition: "Local Symbol", extraHumanReadable: "Local. Abosulte: \(self.isSymbolAbsolute)")]
        } else {
            let symbolName = self.symbolTable?.findSymbol(atIndex: Int(self.symbolTableIndex)).symbolName
            return [GeneralTranslation(definition: "Symbol Table Index", humanReadable: "\(self.symbolTableIndex)",
                                bytesCount: 4, translationType: .uint32,
                                extraDefinition: "Referrenced Symbol", extraHumanReadable: symbolName)]
        }
    }
    
    static var modelSizeFor32Bit: Int { 4 }
    static var modelSizeFor64Bit: Int { 4 }
}
