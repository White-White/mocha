//
//  IndirectSymbolTableEntry.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/6.
//

import Foundation


struct IndirectSymbolTableEntry: InterpretableModel {
    
    let symbolTableIndex: UInt32
    weak var macho: Macho?
    
    init(with data: Data, is64Bit: Bool, macho: Macho) {
        self.symbolTableIndex = data.UInt32
        self.macho = macho
    }
    
    var translations: [Translation] {
        var symbolName: String?
        if let symbolTableEntry = macho?.symbolTable?.symbol(atIndex: Int(self.symbolTableIndex)),
           let _symbolName = macho?.stringTable?.findString(at: Int(symbolTableEntry.indexInStringTable)) {
            symbolName = _symbolName
        }
        
        return [Translation(description: "Symbol Table Index", explanation: "\(self.symbolTableIndex)",
                            bytesCount: 4,
                            extraDescription: "Referrenced Symbol", extraExplanation: symbolName)]
    }
    
    static var modelSizeFor32Bit: Int { 4 }
    static var modelSizeFor64Bit: Int { 4 }
}
