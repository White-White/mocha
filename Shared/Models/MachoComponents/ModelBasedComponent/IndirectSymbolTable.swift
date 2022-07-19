//
//  IndirectSymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class IndirectSymbolTable: ModelBasedComponent<IndirectSymbolTableEntry> {
    
    override var initDependencies: [MachoComponent?] { [macho?.symbolTable] }
    
    func findIndirectSymbol(atIndex index: Int) -> IndirectSymbolTableEntry {
        var indirectSymbolTableEntry: IndirectSymbolTableEntry!
        self.withInitializationDone {
            guard index < self.models.count else { fatalError() }
            indirectSymbolTableEntry = self.models[index]
        }
        return indirectSymbolTableEntry
    }
    
}
