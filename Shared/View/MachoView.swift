//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

extension Macho {
    fileprivate var machoViewCellModels: [SmartDataContainer & TranslationStoreDataSource] {
        var cellModels: [SmartDataContainer & TranslationStoreDataSource] = [self.header]
        
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
}


fileprivate struct MachoCellView: View {
    
    let cellModel: SmartDataContainer
    let hexDigits: Int
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
                Text(String(format: "Range: 0x%0\(hexDigits)X ~ 0x%0\(hexDigits)X", cellModel.startOffsetInMacho, cellModel.startOffsetInMacho + cellModel.dataSize))
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
    
    init(_ cellModel: SmartDataContainer, isSelected: Bool) {
        self.cellModel = cellModel
        self.hexDigits = cellModel.smartData.preferredNumberOfHexDigits
        self.isSelected = isSelected
    }
}

struct MachoView: View {
    
    @Binding var macho: Macho
    @State fileprivate var selectedCellIndex: Int
    @State fileprivate var cellModels: [SmartDataContainer & TranslationStoreDataSource]
    
    @State var binaryStore: HexLineStore
    @State var selectedBinaryRange: Range<Int>?
    @State var translationStore: TranslationStore
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<cellModels.count, id: \.self) { index in
                        MachoCellView(cellModels[index], isSelected: selectedCellIndex == index)
                            .onTapGesture {
                                self.selectedCellIndex = index
                                self.binaryStore = cellModels[index].binaryStore
                                self.translationStore = TranslationStore(dataSource: cellModels[index])
                            }
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
            .fixedSize(horizontal: true, vertical: false)
            
            Divider()
            
            VStack(alignment: .leading) {
                MiniMap(size: macho.fileSize, start: cellModels[selectedCellIndex].startOffsetInMacho, length: cellModels[selectedCellIndex].dataSize)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                HStack(alignment: .top, spacing: 0) {
                    HexView(store: $binaryStore, selectedBinaryRange: $selectedBinaryRange)
                    TranslationView(store: $translationStore, selectedBinaryRange: $selectedBinaryRange)
                }
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4))
            }
        }
        .onChange(of: macho) { newValue in
            self.cellModels = newValue.machoViewCellModels
            self.selectedCellIndex = .zero
            
            self.binaryStore = newValue.header.binaryStore
            self.selectedBinaryRange = newValue.header.translationSection(at: 0).terms.first?.range
            self.translationStore = TranslationStore(dataSource: newValue.header)
        }
    }
    
    init(_ macho: Binding<Macho>) {
        _macho = macho
        _cellModels = State(initialValue: macho.wrappedValue.machoViewCellModels)
        _selectedCellIndex = State(initialValue: .zero)
        
        _binaryStore = State(initialValue: macho.wrappedValue.header.binaryStore)
        _selectedBinaryRange = State(initialValue: macho.wrappedValue.header.translationSection(at: 0).terms.first?.range)
        _translationStore = State(initialValue: TranslationStore(dataSource: macho.wrappedValue.header))
    }
}
