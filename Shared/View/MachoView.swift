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
        cellModels.append(contentsOf: self.loadCommands)
        cellModels.append(contentsOf: self.translatorContainers)
        if let relocation = self.relocation { cellModels.append(relocation) }
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
                    .lineLimit(1)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .black)
                    .padding(.bottom, 2)
                if let secondaryDescription = cellModel.secondaryName {
                    Text(secondaryDescription)
                        .font(.system(size: 12))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .lineLimit(1)
                }
                Text(String(format: "Range: 0x%0\(hexDigits)X ~ 0x%0\(hexDigits)X", cellModel.startOffsetInMacho, cellModel.startOffsetInMacho + cellModel.dataSize))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .padding(.top, 2)
                    .lineLimit(1)
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
    
    @State var miniMapStart: Int
    @State var miniMapLength: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<cellModels.count, id: \.self) { index in
                        MachoCellView(cellModels[index], isSelected: selectedCellIndex == index)
                            .onTapGesture {
                                self.selectedCellIndex = index
                                self.updateUI(with: cellModels[index])
                            }
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
            .fixedSize(horizontal: true, vertical: false)
            
            Divider()
            
            VStack(alignment: .leading) {
                MiniMap(size: macho.fileSize, start: $miniMapStart, length: $miniMapLength)
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
            self.updateUI(with: newValue.header)
        }
    }
    
    init(_ macho: Binding<Macho>) {
        _macho = macho
        
        // cells
        _cellModels = State(initialValue: macho.wrappedValue.machoViewCellModels)
        _selectedCellIndex = State(initialValue: .zero)
        
        // binary store
        let header = macho.wrappedValue.header
        let binaryStore = header.binaryStore
        let selectedRange = header.translationSection(at: 0).terms.first?.range
        binaryStore.updateLinesWith(selectedBytesRange: selectedRange)
        _binaryStore = State(initialValue: binaryStore)
        _selectedBinaryRange = State(initialValue: selectedRange)
        _translationStore = State(initialValue: TranslationStore(dataSource: header))
        
        // mini map
        _miniMapStart = State(initialValue: header.startOffsetInMacho)
        _miniMapLength = State(initialValue: header.dataSize)
    }
    
    func updateUI(with model: SmartDataContainer & TranslationStoreDataSource) {
        self.binaryStore = model.binaryStore
        let selectedRange = model.translationSection(at: 0).terms.first?.range
        self.binaryStore.updateLinesWith(selectedBytesRange: selectedRange)
        self.translationStore = TranslationStore(dataSource:model)
        self.selectedBinaryRange = selectedRange
        
        // mini map
        self.miniMapStart = model.startOffsetInMacho
        self.miniMapLength = model.dataSize
    }
}
