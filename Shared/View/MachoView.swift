//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

struct MachoView: View {
    
    let macho: Macho
    @State var cellModels: [MachoViewCellModel]
    @State var selectedCellModel: MachoViewCellModel
    
    @State var selectedDataRange: Range<UInt64>
    @State var selectedMachoComponent: MachoComponent
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            HStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(cellModels) { cellModel in
                            MachoComponentCellView(cellModel: cellModel, machoFileSize: macho.fileSize, hexDigits: macho.hexDigits)
                                .onTapGesture {
                                    if self.selectedCellModel.machoComponent == cellModel.machoComponent { return }
                                    cellModel.isSelected.toggle()
                                    self.selectedCellModel.isSelected.toggle()
                                    self.selectedCellModel = cellModel
                                    self.selectedMachoComponent = cellModel.machoComponent
                                }
                        }
                    }
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                }
                .fixedSize(horizontal: true, vertical: false)
                .onChange(of: macho) { newValue in
                    if let id = cellModels.first?.id {
                        scrollViewProxy.scrollTo(id, anchor: .top)
                    }
                }
                Divider()
                HexFiendView(data: macho.machoData, selectedRange: $selectedDataRange)
                MachoComponentView(with: $selectedMachoComponent, hexDigits: macho.hexDigits, selectedRange: $selectedDataRange)
            }
        }
        .onChange(of: macho) { newValue in
            let cellModels = newValue.machoComponents.map { MachoViewCellModel.init($0) }
            let firstCellModel = cellModels.first!
            firstCellModel.isSelected = true
            
            self.cellModels = cellModels
            self.selectedMachoComponent = firstCellModel.machoComponent
            self.selectedCellModel = firstCellModel
            
            let firstTranslationItem = firstCellModel.machoComponent.translationItem(at: IndexPath(item: .zero, section: .zero))
            self.selectedDataRange = firstTranslationItem.sourceDataRange
        }
    }
    
    init(_ macho: Macho) {
        macho.initialize()
        self.macho = macho
        let cellModels = macho.machoComponents.map { MachoViewCellModel.init($0) }
        let firstCellModel = cellModels.first!
        firstCellModel.isSelected = true
        
        _cellModels = State(initialValue: cellModels)
        _selectedMachoComponent = State(initialValue: firstCellModel.machoComponent)
        _selectedCellModel = State(initialValue: firstCellModel)
        
        let firstTranslationItem = firstCellModel.machoComponent.translationItem(at: IndexPath(item: .zero, section: .zero))
        _selectedDataRange = State(initialValue: firstTranslationItem.sourceDataRange)
    }
}
