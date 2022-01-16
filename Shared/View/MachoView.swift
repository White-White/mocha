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
                Text(cellModel.machoComponent.componentTitle)
                    .font(.system(size: 13).bold())
                    .foregroundColor(cellModel.isSelected ? .white : .black)
                    .padding(.bottom, 2)
                if let primaryName = cellModel.machoComponent.componentSubTitle {
                    Text(primaryName)
                        .font(.system(size: 12))
                        .foregroundColor(cellModel.isSelected ? .white : .black)
                        .padding(.bottom, 2)
                }
                if let secondaryDescription = cellModel.machoComponent.componentDescription {
                    Text(secondaryDescription)
                        .font(.system(size: 12))
                        .foregroundColor(cellModel.isSelected ? .white : .secondary)
                        .lineLimit(1)
                        .padding(.bottom, 2)
                }
                Text(String(format: "Range: 0x%0\(hexDigits)X - 0x%0\(hexDigits)X", cellModel.machoComponent.fileOffsetInMacho, cellModel.machoComponent.fileOffsetInMacho + cellModel.machoComponent.size))
                    .font(.system(size: 12))
                    .foregroundColor(cellModel.isSelected ? .white : .secondary)
                    .padding(.trailing, 8) // extra space for complete range info
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
    
    @State var cellModels: [MachoViewCellModel]
    @State var selectedCellModel: MachoViewCellModel?
    @State var selectedMachoComponent: MachoComponent
    @State var hexStore: HexLineStore
    @State var selectedDataRange: Range<Int>?
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(cellModels, id: \.machoComponent.fileOffsetInMacho) { cellModel in
                        MachoComponentView(cellModel: cellModel)
                            .onTapGesture {
                                if self.selectedCellModel?.machoComponent == cellModel.machoComponent { return }
                                self.selectedMachoComponent = cellModel.machoComponent
                                self.selectedDataRange = cellModel.machoComponent.firstTransItem.sourceDataRange
                                self.hexStore = HexLineStore(cellModel.machoComponent.machoDataSlice)
                                self.hexStore.updateLinesWith(selectedBytesRange: self.selectedDataRange)
                                
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
                    HexView(store: $hexStore, selectedDataRange: $selectedDataRange)
                    TranslationView(machoComponent: selectedMachoComponent, sourceDataRangeOfSelecteditem: $selectedDataRange)
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
            self.selectedDataRange = newValue.header.firstTransItem.sourceDataRange
            self.hexStore.updateLinesWith(selectedBytesRange: self.selectedDataRange)
        }
    }
    
    init(_ macho: Binding<Macho>) {
        _macho = macho
        let machoUnwrapp = macho.wrappedValue
        
        let cellModels = machoUnwrapp.machoComponents.map { MachoViewCellModel.init($0) }
        cellModels.first?.isSelected = true
        _cellModels = State(initialValue: cellModels)
        _selectedCellModel = State(initialValue: cellModels.first)
        
        _selectedMachoComponent = State(initialValue: machoUnwrapp.machoComponents.first!)
        let selectedRange = macho.wrappedValue.header.firstTransItem.sourceDataRange
        _selectedDataRange = State(initialValue: selectedRange)
        let hexStore = HexLineStore(macho.wrappedValue.header.machoDataSlice)
        hexStore.updateLinesWith(selectedBytesRange: selectedRange)
        _hexStore = State(initialValue: hexStore)
    }
}
