//
//  ComponentListView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/17.
//

import SwiftUI

class ComponentListCellModel: ObservableObject, Identifiable {
    
    var id: Int { index }
    let index: Int
    let title: String
    let offsetInMacho: Int
    let dataSize: Int
    @Published var isSelected: Bool
    
    init(_ component: MachoComponent, index: Int, isSelected: Bool) {
        self.title = component.title
        self.offsetInMacho = component.offsetInMacho
        self.dataSize = component.dataSize
        self.index = index
        self.isSelected = isSelected
    }
    
    static func createModels(from macho: Macho, selectedIndex: Int) -> [ComponentListCellModel] {
        var cellModels: [ComponentListCellModel] = []
        for (index, machoComponent) in macho.allComponents.enumerated() {
            cellModels.append(ComponentListCellModel(machoComponent, index: index, isSelected: selectedIndex == index))
        }
        return cellModels
    }
    
}

struct ComponentListCell: View {
    
    @ObservedObject var cellModel: ComponentListCellModel
    var isSelected: Bool { cellModel.isSelected }
    var title: String { cellModel.title }
    var offsetInMacho: Int { cellModel.offsetInMacho }
    var dataSize: Int { cellModel.dataSize }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 12).bold())
                        .padding(.bottom, 2)
                    Text(String(format: "Range: 0x%0X - 0x%0X", offsetInMacho, offsetInMacho + dataSize))
                    .font(.system(size: 11))
                    
                    Text(String(format: "Size: 0x%0X(%d) Bytes", dataSize, dataSize))
                        .font(.system(size: 11))
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                Divider()
            }
        }
        .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
    }
    
}

struct ComponentListView: View {
    
    @Binding var selectedMachoComponentIndex: Int
    let cellModels: [ComponentListCellModel]
    
    var widthNeeded: CGFloat {
        return cellModels.reduce(0) { partialResult, cellModel in
            let attriString = NSAttributedString(string: cellModel.title, attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)])
            let recommendedWidth = attriString.boundingRect(with: NSSize(width: 1000, height: 0), options: .usesLineFragmentOrigin).size.width
            return max(partialResult, recommendedWidth)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(cellModels) { cellModel in
                    ComponentListCell(cellModel: cellModel)
                        .onTapGesture {
                            if cellModel.isSelected { return }
                            cellModels[selectedMachoComponentIndex].isSelected.toggle()
                            cellModel.isSelected.toggle()
                            self.selectedMachoComponentIndex = cellModel.index
                        }
                }
            }
        }
        .border(.separator, width: 1)
        .frame(width: widthNeeded + 16)
    }
    
    init(macho: Macho, selectedMachoComponentIndex: Binding<Int>) {
        self.cellModels = ComponentListCellModel.createModels(from: macho, selectedIndex: selectedMachoComponentIndex.wrappedValue)
        _selectedMachoComponentIndex = selectedMachoComponentIndex
    }
    
}
