//
//  MachoComponentCellView.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/28.
//

import SwiftUI

struct MachoComponentCellView: View {
    
    @ObservedObject var cellModel: MachoViewCellModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(cellModel.machoComponent.title)
                    .font(.system(size: 13).bold())
                    .padding(.bottom, 2)
                if let primaryName = cellModel.machoComponent.subTitle {
                    Text(primaryName)
                        .font(.system(size: 12))
                        .padding(.bottom, 2)
                }
                Text(String(format: "Range: 0x%0X - 0x%0X",
                            cellModel.machoComponent.offsetInMacho, cellModel.machoComponent.offsetInMacho + cellModel.machoComponent.dataSize))
                    .font(.system(size: 12))
                
                Text(String(format: "Size: 0x%0X(%d) Bytes", cellModel.machoComponent.dataSize, cellModel.machoComponent.dataSize))
                    .font(.system(size: 12))
                
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(cellModel.isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
        }
        .contentShape(Rectangle())
        .frame(width: 200)
    }
}

class MachoViewCellModel: ObservableObject, Identifiable {
    let id = UUID()
    var machoComponent: MachoComponent
    @Published var isSelected: Bool = false
    init(_ c: MachoComponent) { self.machoComponent = c }
}
