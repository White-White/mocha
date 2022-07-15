//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class SymbolTable: ModelBasedComponent<SymbolTableEntry> {
    
    func findSymbol(byVirtualAddress virtualAddress: UInt64) -> SymbolTableEntry? {
        return self.models.first { $0.nValue == virtualAddress && $0.symbolType == .section }
    }
    
    func symbol(atIndex index: Int) -> SymbolTableEntry {
        guard index < self.models.count else { fatalError() }
        return self.models[index]
    }
    
}


