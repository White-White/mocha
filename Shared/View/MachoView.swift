//
//  MachoView.swift
//  mocha
//
//  Created by white on 2021/6/18.
//

import SwiftUI

struct MachoView: View {
    
    @Binding var macho: Macho
    @State var cellModels: [MachoViewCellModel]
    @State var selectedMachoComponent: MachoComponent
    @State var selectedCellModel: MachoViewCellModel
    
    var body: some View {
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
            
            Divider()
            
            MachoComponentView(with: $selectedMachoComponent, hexDigits: macho.hexDigits)
        }
        .onChange(of: macho) { newValue in
            let cellModels = newValue.machoComponents.map { MachoViewCellModel.init($0) }
            let firstCellModel = cellModels.first!
            firstCellModel.isSelected = true
            
            self.cellModels = cellModels
            self.selectedMachoComponent = firstCellModel.machoComponent
            self.selectedCellModel = firstCellModel
        }
    }
    
    init(_ macho: Binding<Macho>) {
        _macho = macho
        let cellModels = macho.wrappedValue.machoComponents.map { MachoViewCellModel.init($0) }
        let firstCellModel = cellModels.first!
        firstCellModel.isSelected = true
        
        _cellModels = State(initialValue: cellModels)
        _selectedMachoComponent = State(initialValue: firstCellModel.machoComponent)
        _selectedCellModel = State(initialValue: firstCellModel)
    }
}
