//
//  ComponentListView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/17.
//

import SwiftUI

struct ComponentListCell: View {
    
    let machoElement: MachoBaseElement
    let isSelected: Bool
    var title: String { machoElement.title }
    var offsetInMacho: Int { machoElement.offsetInMacho }
    var dataSize: Int { machoElement.dataSize }
    
    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 12).bold())
                        .padding(.bottom, 2)
                    
                    if let subTitle = machoElement.subTitle {
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
            .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
        }
    }
    
    static func widthNeeded(for allMachoElements: [MachoBaseElement]) -> CGFloat {
        return allMachoElements.reduce(0) { partialResult, component in
            let attriString = NSAttributedString(string: component.title, attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)])
            let recommendedWidth = attriString.boundingRect(with: NSSize(width: 1000, height: 0), options: .usesLineFragmentOrigin).size.width
            return max(partialResult, recommendedWidth)
        } + 16
    }
    
}
