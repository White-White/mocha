//
//  IndirectSymbolTableEntry.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/6.
//

import Foundation


struct IndirectSymbolTableEntry: InterpretableModel {
    
    let entryRange: Range<Int>
    let symbolTableIndex: Int
    weak var macho: Macho?
    
    init(with data: Data, is64Bit: Bool, macho: Macho) {
        self.entryRange = data.absoluteRange(.zero, 4)
        self.symbolTableIndex = Int(data.UInt32)
        self.macho = macho
    }
    
    func translationItem(at index: Int) -> TranslationItem {
        var symbolName: String?
        if let symbolTableEntry = macho?.symbolInSymbolTable(at: symbolTableIndex),
           let _symbolName = macho?.stringInStringTable(at: Int(symbolTableEntry.indexInStringTable)) {
            symbolName = _symbolName
        }
        return TranslationItem(sourceDataRange: entryRange,
                               content: TranslationItemContent(description: "Symbol Table Index",
                                                               explanation: "\(symbolTableIndex)",
                                                               extraDescription: "Referrenced Symbol",
                                                               extraExplanation: symbolName))
    }
    
    static func modelSize(is64Bit: Bool) -> Int {
        return 4
    }
    
    static func numberOfTranslationItems() -> Int {
        return 1
    }
}
