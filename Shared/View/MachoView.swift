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
    @State var translationGroup: TranslationGroup
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            HStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(cellModels) { cellModel in
                            MachoComponentCellView(cellModel: cellModel)
                                .onTapGesture {
                                    if self.selectedCellModel.machoComponent == cellModel.machoComponent { return }
                                    cellModel.isSelected.toggle()
                                    self.selectedCellModel.isSelected.toggle()
                                    self.selectedCellModel = cellModel
                                    self.translationGroup = cellModel.machoComponent.translationGroup
                                    
//                                    let firstTranslation = cellModel.machoComponent.firstTranslation
//                                    self.selectedDataRange = firstTranslation.dataRange
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
                
                TranslationGroupView(translationGroup: translationGroup, selectedRange: $selectedDataRange)
                
                HexFiendView(data: macho.machoData, selectedRange: $selectedDataRange)
            }
        }
        .onChange(of: macho) { newValue in
            let cellModels = newValue.allComponents.map { MachoViewCellModel.init($0) }
            let firstCellModel = cellModels.first!
            firstCellModel.isSelected = true
            
            self.cellModels = cellModels
            self.translationGroup = firstCellModel.machoComponent.translationGroup
            self.selectedCellModel = firstCellModel
            
//            let firstTranslation = firstCellModel.machoComponent.firstTranslation
        }
    }
    
    init(_ macho: Macho) {
        self.macho = macho
        let cellModels = macho.allComponents.map { MachoViewCellModel.init($0) }
        let firstCellModel = cellModels.first!
        firstCellModel.isSelected = true
        
        _cellModels = State(initialValue: cellModels)
        _translationGroup = State(initialValue: firstCellModel.machoComponent.translationGroup)
        _selectedCellModel = State(initialValue: firstCellModel)
        
//        let firstTranslation = firstCellModel.machoComponent.firstTranslation
        _selectedDataRange = State(initialValue: 0..<1)
    }
}
