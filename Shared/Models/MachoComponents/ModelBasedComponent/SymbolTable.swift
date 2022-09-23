//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class SymbolTable: ModelBasedComponent<SymbolTableEntry> {
    
    override var macho: Macho? {
        didSet {
            guard let stringTable = self.macho?.stringTable else { fatalError() }
            self.addDependency(stringTable)
        }
    }
    
    private var symbolTableEntryMap: [UInt64: [Int]] = [:]
    
    override func asyncInitialize() {
        super.asyncInitialize()
        for (index, symbolEntry) in self.models.enumerated() {
            
            /* comments from LinkEdit.m in MachoOView code base
            // it is possible to associate more than one symbol to the same address.
            // every new symbol will be appended to the list
            */
            
            if let existedIndexs = symbolTableEntryMap[symbolEntry.nValue] {
                symbolTableEntryMap[symbolEntry.nValue] = existedIndexs + [index]
            } else {
                symbolTableEntryMap[symbolEntry.nValue] = [index]
            }
        }
    }
    
    func findSymbol(byVirtualAddress virtualAddress: UInt64) -> [SymbolTableEntry]? {
        var symbolTableEntrys: [SymbolTableEntry] = []
        if let symbolTableEntryIndexs = symbolTableEntryMap[virtualAddress] {
            symbolTableEntrys = symbolTableEntryIndexs.map { self.models[$0] }
        }
        return symbolTableEntrys
    }
    
    func findSymbol(atIndex index: Int) -> SymbolTableEntry {
        guard index < self.models.count else { fatalError() }
        return self.models[index]
    }
    
}


