//
//  IndirectSymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class IndirectSymbolTable: ModelBasedComponent<IndirectSymbolTableEntry> {
    
    func indirectSymbol(atIndex index: Int) -> IndirectSymbolTableEntry {
        guard index < self.models.count else { fatalError() }
        return self.models[index]
    }
    
}
