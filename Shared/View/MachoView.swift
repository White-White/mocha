//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

fileprivate protocol MachoViewCellModel {
    var startOffsetInMacho: Int { get }
    var dataSizeInMacho: Int { get }
    var primaryName: String { get }
    var secondaryName: String? { get }
    var idForCellModel: UUID { get }
}

extension MachoHeader : MachoViewCellModel {
    var startOffsetInMacho: Int { .zero }
    var dataSizeInMacho: Int { dataSize }
    var primaryName: String { "Macho Header" }
    var secondaryName: String? { "Macho Header" }
    var idForCellModel: UUID { id }
}

extension LoadCommand : MachoViewCellModel {
    var startOffsetInMacho: Int { offsetInMacho }
    var dataSizeInMacho: Int { loadCommandSize }
    var primaryName: String { loadCommandType.commandName }
    var secondaryName: String? { "Load Command" }
    var idForCellModel: UUID { id }
}

extension MergedLinkOptionsCommand : MachoViewCellModel {
    var startOffsetInMacho: Int { offsetInMacho }
    var dataSizeInMacho: Int { dataSize }
    var primaryName: String { LoadCommandType.linkerOption.commandName + "(s)" }
    var secondaryName: String? { "\(linkerOptions.count) linker options" }
    var idForCellModel: UUID { id }
}

extension Section : MachoViewCellModel {
    var startOffsetInMacho: Int { Int(header.offset) }
    var dataSizeInMacho: Int { Int(header.size) }
    var primaryName: String { header.segment + "," + header.section }
    var secondaryName: String? { "Section" }
    var idForCellModel: UUID { id }
}

extension SymbolTable : MachoViewCellModel {
    var startOffsetInMacho: Int { offsetInMacho }
    var dataSizeInMacho: Int { dataSize }
    var primaryName: String { "Symbol Table" }
    var secondaryName: String? { "Symbol Table" }
    var idForCellModel: UUID { id }
}

extension StringTable : MachoViewCellModel {
    var startOffsetInMacho: Int { offsetInMacho }
    var dataSizeInMacho: Int { dataSize }
    var primaryName: String { "String Table" }
    var secondaryName: String? { "String Table" }
    var idForCellModel: UUID { id }
}

extension Relocation : MachoViewCellModel {
    var startOffsetInMacho: Int { offsetInMacho }
    var dataSizeInMacho: Int { dataSize }
    var primaryName: String { "Relocation Entries" }
    var secondaryName: String? { "\(entries.count) entries" }
    var idForCellModel: UUID { id }
}

extension Macho {
    fileprivate var machoViewCellModels: [MachoViewCellModel & BinaryTranslationStoreGenerator] {
        var cellModels: [MachoViewCellModel & BinaryTranslationStoreGenerator] = [self.header]
        
        // append load commands and section headers
        cellModels.append(contentsOf: self.loadCommands)
        
        // append merged linker options
        if let mergedLinkerOptions = self.mergedLinkerOptions {
            cellModels.append(mergedLinkerOptions)
        }
        
        // append sections
        cellModels.append(contentsOf: self.sections)
        
        // append relocation entries
        if let relocation = self.relocation {
            cellModels.append(relocation)
        }
        
        // append symbol table &
        if let symbolTable = self.symbolTable {
            cellModels.append(symbolTable)
        }
        
        // append string table
        if let stringTable = self.stringTable {
            cellModels.append(stringTable)
        }
        
        return cellModels
    }
    
    fileprivate var digits: Int {
        var machoFileSize = self.fileSize
        var digitCount = 0
        while machoFileSize != 0 {
            digitCount += 1
            machoFileSize /= 16
        }
        return digitCount
    }
}


fileprivate struct MachoCellView: View {
    
    let cellModel: MachoViewCellModel
    let digitsCount: Int
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(cellModel.primaryName)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .black)
                    .padding(.bottom, 2)
                if let secondaryDescription = cellModel.secondaryName {
                    Text(secondaryDescription)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                Text(String(format: "Range: 0x%0\(digitsCount)X ~ 0x%0\(digitsCount)X", cellModel.startOffsetInMacho, cellModel.startOffsetInMacho + cellModel.dataSizeInMacho))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .padding(.top, 2)
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(isSelected ? Theme.selected : .white)
        }
        .contentShape(Rectangle())
    }
    
    init(_ cellModel: MachoViewCellModel, digitsCount: Int, isSelected: Bool) {
        self.cellModel = cellModel
        self.digitsCount = digitsCount
        self.isSelected = isSelected
    }
}


struct MachoView: View {
    
    @Binding var macho: Macho
    @State var digitCount: Int
    @State fileprivate var cellModels: [MachoViewCellModel & BinaryTranslationStoreGenerator]
    @State fileprivate var selectedModel: MachoViewCellModel
    @State var binaryTranslationStore: BinaryTranslationStore
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(cellModels, id: \.idForCellModel) { cellModel in
                        MachoCellView(cellModel, digitsCount: digitCount, isSelected: selectedModel.idForCellModel == cellModel.idForCellModel)
                            .onTapGesture {
                                self.selectedModel = cellModel
                                self.binaryTranslationStore = cellModel.binaryTranslationStore()
                            }
                    }
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            .fixedSize(horizontal: true, vertical: false)
            
            Divider()
            
            VStack(alignment: .leading) {
                MiniMap(size: macho.fileSize, start: selectedModel.startOffsetInMacho, length: selectedModel.dataSizeInMacho)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                BinaryView($binaryTranslationStore, digitsCount: $digitCount)
                    .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            }
        }
        .onChange(of: macho) { newValue in
            self.selectedModel = newValue.header
            self.binaryTranslationStore = newValue.header.binaryTranslationStore()
            self.digitCount = newValue.digits
            self.cellModels = newValue.machoViewCellModels
        }
    }
    
    init(_ macho: Binding<Macho>) {
        _macho = macho
        _selectedModel = State(initialValue: macho.wrappedValue.header)
        _binaryTranslationStore = State(initialValue: macho.wrappedValue.header.binaryTranslationStore())
        _digitCount = State(initialValue: macho.wrappedValue.digits)
        _cellModels = State(initialValue: macho.wrappedValue.machoViewCellModels)
    }
}
