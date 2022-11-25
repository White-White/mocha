//
//  IndirectSymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class IndirectSymbolTable: ModelBasedComponent<IndirectSymbolTableEntry> {
    
    override var macho: Macho? {
        didSet {
            guard let symbolTable = self.macho?.symbolTable else { fatalError() }
            self.parentComponent = symbolTable
        }
    }
    
    func findIndirectSymbol(atIndex index: Int) -> IndirectSymbolTableEntry {
        guard index < self.models.count else { fatalError() }
        return self.models[index]
    }
    
}
