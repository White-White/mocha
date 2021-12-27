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
    
    let digitCount: Int
    let macho: Macho
    fileprivate let cellModels: [MachoViewCellModel & BinaryTranslationStoreGenerator]
    
    @State fileprivate var selectedModel: MachoViewCellModel?
    @State var binaryTranslationStore: BinaryTranslationStore?
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(cellModels, id: \.idForCellModel) { cellModel in
                        MachoCellView(cellModel, digitsCount: digitCount, isSelected: selectedModel?.idForCellModel == cellModel.idForCellModel)
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
                MiniMap(size: macho.fileSize, start: selectedModel?.startOffsetInMacho, length: selectedModel?.dataSizeInMacho)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                if let binaryTranslationStore = binaryTranslationStore {
                    BinaryView(binaryTranslationStore, digitsCount: digitCount)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                } else {
                    Spacer()
                }
            }
        }
    }
    
    init(_ macho: Macho) {
        self.macho = macho
        var machoFileSize = macho.fileSize
        var digitCount = 0
        while machoFileSize != 0 {
            digitCount += 1
            machoFileSize /= 16
        }
        self.digitCount = digitCount
        
        var cellModels: [MachoViewCellModel & BinaryTranslationStoreGenerator] = [macho.header]
        
        // append load commands and section headers
        cellModels.append(contentsOf: macho.loadCommands)
        
        // append merged linker options
        if let mergedLinkerOptions = macho.mergedLinkerOptions {
            cellModels.append(mergedLinkerOptions)
        }
        
        // append sections
        cellModels.append(contentsOf: macho.sections)
        
        // append relocation entries
        if let relocation = macho.relocation {
            cellModels.append(relocation)
        }
        
        // append symbol table &
        if let symbolTable = macho.symbolTable {
            cellModels.append(symbolTable)
        }
        
        // append string table
        if let stringTable = macho.stringTable {
            cellModels.append(stringTable)
        }
        
        self.cellModels = cellModels
    }
}
