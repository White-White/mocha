//
//  IndirectSymbolInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/5.
//

import Foundation

struct DummyIndirectSymbolTableEntry { }

class IndirectSymbolInterpreter: BaseInterpreter<[DummyIndirectSymbolTableEntry]> {
    
    override var payload: [DummyIndirectSymbolTableEntry] { fatalError() }
    
    override var numberOfTranslationItems: Int {
        return self.data.count / 4
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let symbolIndex = self.data.truncated(from: index * 4, length: 4).raw.UInt32
        var symbolName: String?
        if let functionSymbol = self.machoSearchSource.symbolInSymbolTable(with: Int(symbolIndex)),
           let _symbolName = self.machoSearchSource.stringInStringTable(at: Int(functionSymbol.indexInStringTable)) {
            symbolName = _symbolName
        }
        return TranslationItem(sourceDataRange: self.data.absoluteRange(index * 4, 4),
                               content: TranslationItemContent(description: "Symbol Table Index",
                                                               explanation: "\(symbolIndex)",
                                                               extraDescription: "Referrenced Symbol",
                                                               extraExplanation: symbolName))
    }
}
