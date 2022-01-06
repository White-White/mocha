//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

struct MachoComponentView: View {
    
    @ObservedObject var cellModel: MachoViewCellModel
    
    var hexDigits: Int {
        cellModel.machoComponent.machoDataSlice.preferredNumberOfHexDigits
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(cellModel.machoComponent.title)
                    .font(.system(size: 13).bold())
                    .foregroundColor(cellModel.isSelected ? .white : .black)
                    .padding(.bottom, 2)
                if let primaryName = cellModel.machoComponent.primaryName {
                    Text(primaryName)
                        .font(.system(size: 12))
                        .foregroundColor(cellModel.isSelected ? .white : .black)
                        .padding(.bottom, 2)
                }
                if let secondaryDescription = cellModel.machoComponent.secondaryName {
                    Text(secondaryDescription)
                        .font(.system(size: 12))
                        .foregroundColor(cellModel.isSelected ? .white : .secondary)
                        .lineLimit(1)
                        .padding(.bottom, 2)
                }
                Text(String(format: "Rnage: 0x%0\(hexDigits)X - 0x%0\(hexDigits)X", cellModel.machoComponent.fileOffsetInMacho, cellModel.machoComponent.fileOffsetInMacho + cellModel.machoComponent.size))
                    .font(.system(size: 12))
                    .foregroundColor(cellModel.isSelected ? .white : .secondary)
                    .padding(.trailing, 8) // extra space for complete range info
                Text(String(format: "Size: 0x%0\(hexDigits)X", cellModel.machoComponent.size))
                    .font(.system(size: 12))
                    .foregroundColor(cellModel.isSelected ? .white : .secondary)
                    .padding(.top, 2)
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(cellModel.isSelected ? Theme.selected : .white)
        }
        .contentShape(Rectangle())
    }
}

class MachoViewCellModel: ObservableObject {
    let machoComponent: MachoComponent
    @Published var isSelected: Bool = false
    init(_ c: MachoComponent) { self.machoComponent = c }
}

struct MachoView: View {
    
    @Binding var macho: Macho
    
    @State fileprivate var cellModels: [MachoViewCellModel]
    @State fileprivate var selectedCellModel: MachoViewCellModel?
    @State fileprivate var selectedMachoComponent: MachoComponent
    @State fileprivate var hexStore: HexLineStore
    @State var selectedBinaryRange: Range<Int>?
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(cellModels, id: \.machoComponent.fileOffsetInMacho) { cellModel in
                        MachoComponentView(cellModel: cellModel)
                            .onTapGesture {
                                if self.selectedCellModel?.machoComponent == cellModel.machoComponent { return }
                                self.selectedMachoComponent = cellModel.machoComponent
                                self.selectedBinaryRange = cellModel.machoComponent.translationSection(at: 0).terms.first?.range
                                self.hexStore = HexLineStore(cellModel.machoComponent.machoDataSlice)
                                self.hexStore.updateLinesWith(selectedBytesRange: self.selectedBinaryRange)
                                
                                cellModel.isSelected.toggle()
                                self.selectedCellModel?.isSelected.toggle()
                                self.selectedCellModel = cellModel
                            }
                    }
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            }
            .fixedSize(horizontal: true, vertical: false)
            
            Divider()
            
            VStack(alignment: .leading) {
                MiniMap(machoFileSize: macho.fileSize, selectedMachoComponent: $selectedMachoComponent)
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 4))
                HStack(alignment: .top, spacing: 0) {
                    HexView(store: $hexStore, selectedBinaryRange: $selectedBinaryRange)
                    TranslationView(machoComponent: $selectedMachoComponent, selectedBinaryRange: $selectedBinaryRange)
                }
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4))
            }
        }
        .onChange(of: macho) { newValue in
            self.cellModels = newValue.machoComponents.map { MachoViewCellModel($0) }
            self.cellModels.first?.isSelected = true
            self.selectedCellModel = self.cellModels.first
            self.selectedMachoComponent = newValue.header
            self.hexStore = HexLineStore(newValue.header.machoDataSlice)
            self.selectedBinaryRange = newValue.header.translationSection(at: 0).terms.first?.range
            self.hexStore.updateLinesWith(selectedBytesRange: self.selectedBinaryRange)
        }
    }
    
    init(_ macho: Binding<Macho>) {
        _macho = macho
        let machoUnwrapp = macho.wrappedValue
        
        let cellModels = machoUnwrapp.machoComponents.map { MachoViewCellModel.init($0) }
        cellModels.first?.isSelected = true
        _cellModels = State(initialValue: cellModels)
        _selectedCellModel = State(initialValue: cellModels.first)
        
        _selectedMachoComponent = State(initialValue: machoUnwrapp.header)
        let selectedRange = macho.wrappedValue.header.translationSection(at: 0).terms.first?.range
        _selectedBinaryRange = State(initialValue: selectedRange)
        let hexStore = HexLineStore(macho.wrappedValue.header.machoDataSlice)
        hexStore.updateLinesWith(selectedBytesRange: selectedRange)
        _hexStore = State(initialValue: hexStore)
    }
}
