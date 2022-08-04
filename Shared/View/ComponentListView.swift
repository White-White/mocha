//
//  ComponentListView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/17.
//

import SwiftUI


class ComponentListCellModel: ObservableObject, Identifiable, InitProgressDelegate {
    
    var id: Int { index }
    let index: Int
    
    let title: String
    let subTitle: String?
    let offsetInMacho: Int
    let dataSize: Int
    
    @Published var done: Bool = true
    @Published var progress: Float = 1
    @Published var isSelected: Bool
    
    init(_ component: MachoComponent, index: Int, isSelected: Bool) {
        self.title = component.title
        self.subTitle = component.subTitle
        self.offsetInMacho = component.offsetInMacho
        self.dataSize = component.dataSize
        self.index = index
        self.isSelected = isSelected
        component.initProgress.delegate = self
    }
    
    func iniProgressUpdate(with updated: Float, done: Bool) {
        withAnimation {
            self.progress = updated
            self.done = done
        }
    }
}

struct ComponentListCell: View {
    
    @ObservedObject var cellModel: ComponentListCellModel
    var isSelected: Bool { cellModel.isSelected }
    var title: String { cellModel.title }
    var offsetInMacho: Int { cellModel.offsetInMacho }
    var dataSize: Int { cellModel.dataSize }
    var progress: CGFloat { CGFloat(cellModel.progress) }
    
    var body: some View {
        ZStack(alignment: .leading) {
            if !cellModel.done {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { reader in
                        Spacer()
                            .frame(width: reader.size.width * CGFloat(progress))
                            .background(.gray)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 12).bold())
                        .padding(.bottom, 2)
                    
                    if let subTitle = cellModel.subTitle {
                        Text(subTitle)
                            .font(.system(size: 10).bold())
                            .padding(.bottom, 2)
                    }
                    
                    Text(String(format: "Range: 0x%0X - 0x%0X", offsetInMacho, offsetInMacho + dataSize))
                        .font(.system(size: 11))
                    
                    Text(String(format: "Size: 0x%0X(%d) Bytes", dataSize, dataSize))
                        .font(.system(size: 11))
                }
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                Divider()
            }
            .background(cellModel.done ? (isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white) : .white.opacity(0.5))
        }
    }
}

struct ComponentListViewModel {
    
    var alertPresented: Bool = false
    var cellModels: [ComponentListCellModel]
    var widthNeeded: CGFloat
    
    init(with macho: Macho, selectedIndex: Int) {
        var cellModels: [ComponentListCellModel] = []
        for (index, machoComponent) in macho.allComponents.enumerated() {
            cellModels.append(ComponentListCellModel(machoComponent, index: index, isSelected: selectedIndex == index))
        }
        self.cellModels = cellModels
        self.widthNeeded = cellModels.reduce(0) { partialResult, cellModel in
            let attriString = NSAttributedString(string: cellModel.title, attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)])
            let recommendedWidth = attriString.boundingRect(with: NSSize(width: 1000, height: 0), options: .usesLineFragmentOrigin).size.width
            return max(partialResult, recommendedWidth)
        }
    }
    
}

struct ComponentListView: View {
    
    let machoViewState: MachoViewState
    var viewModel: ComponentListViewModel { machoViewState.componentListViewModel }
    @State var alertPresented: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.cellModels) { cellModel in
                    ComponentListCell(cellModel: cellModel)
                        .onTapGesture {
                            guard cellModel.done else { alertPresented = true; return }
                            guard !cellModel.isSelected else { return }
                            self.machoViewState.selectedMachoComponentIndex = cellModel.index
                        }
                }
            }
        }
        .border(.separator, width: 1)
        .frame(width: viewModel.widthNeeded + 16)
        .alert("Component is loading", isPresented: $alertPresented) {
            
        }
    }
  
}
