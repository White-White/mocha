//
//  MachoComponentCellView.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/28.
//

import SwiftUI

struct MachoComponentCellView: View {
    
    @ObservedObject var cellModel: MachoViewCellModel
    let machoFileSize: Int
    let hexDigits: Int
    
    var startPercent: CGFloat {
        CGFloat(cellModel.machoComponent.componentFileOffset) / CGFloat(machoFileSize) * 100
    }
    
    var endPercent: CGFloat {
        startPercent + CGFloat(cellModel.machoComponent.componentSize) / CGFloat(machoFileSize) * 100
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
                Text(String(format: "Range: 0x%0\(hexDigits)X - 0x%0\(hexDigits)X",
                            cellModel.machoComponent.componentFileOffset, cellModel.machoComponent.componentFileOffset + cellModel.machoComponent.componentSize))
                    .font(.system(size: 12))
                    .foregroundColor(cellModel.isSelected ? .white : .secondary)
                
                Text(String(format: "Position: %.4f%% - %.4f%%", startPercent, endPercent))
                    .font(.system(size: 12))
                    .foregroundColor(cellModel.isSelected ? .white : .secondary)
                
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        .background {
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(cellModel.isSelected ? Theme.selected : .white)
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
