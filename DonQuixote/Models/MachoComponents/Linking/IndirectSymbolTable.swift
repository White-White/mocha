//
//  IndirectSymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class IndirectSymbolTable: MachoBaseElement {
    
    let is64Bit: Bool
    let symbolTable: SymbolTable?
    private var indirectSymbolTableEntries: [IndirectSymbolTableEntry] = []
    
    init(_ data: Data, title: String, is64Bit: Bool, symbolTable: SymbolTable?) {
        self.is64Bit = is64Bit
        self.symbolTable = symbolTable
        super.init(data, title: title, subTitle: nil)
    }
    
    override func loadTranslations() async {
        let modelSize = self.is64Bit ? IndirectSymbolTableEntry.modelSizeFor64Bit : IndirectSymbolTableEntry.modelSizeFor32Bit
        let numberOfModels = self.dataSize/modelSize
        for index in 0..<numberOfModels {
            let data = self.data.subSequence(from: index * modelSize, count: modelSize)
            let entry = IndirectSymbolTableEntry(with: data, is64Bit: self.is64Bit, symbolTable: self.symbolTable)
            self.indirectSymbolTableEntries.append(entry)
            let translations = await entry.generateTranslations()
            await self.save(translationGroup: translations)
        }
    }
    
    func findIndirectSymbol(atIndex index: Int) -> IndirectSymbolTableEntry {
        guard index < self.indirectSymbolTableEntries.count else { fatalError() }
        return self.indirectSymbolTableEntries[index]
    }
    
}
