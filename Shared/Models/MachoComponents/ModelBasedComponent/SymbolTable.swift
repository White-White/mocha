//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class SymbolTable: ModelBasedComponent<SymbolTableEntry> {
    
    override var initDependencies: [MachoComponent?] { [macho?.stringTable] }
    
    private var symbolTableEntryMap: [UInt64: [Int]] = [:]
    
    override func initialize() {
        super.initialize()
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
        self.withInitializationDone {
            if let symbolTableEntryIndexs = symbolTableEntryMap[virtualAddress] {
                symbolTableEntrys = symbolTableEntryIndexs.map { self.models[$0] }
            }
        }
        return symbolTableEntrys
    }
    
    func findSymbol(atIndex index: Int) -> SymbolTableEntry {
        var symbolTableEntry: SymbolTableEntry!
        self.withInitializationDone {
            guard index < self.models.count else { fatalError() }
            symbolTableEntry = self.models[index]
        }
        return symbolTableEntry
    }
    
}


