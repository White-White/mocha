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
    
//    @ObservedObject var initProgress: InitProgress
    @State var isDone: Bool = true
    @State var progress: Float = 1
    
    var body: some View {
        ZStack(alignment: .leading) {
            if !isDone {
                VStack(alignment: .leading, spacing: 0) {
                    GeometryReader { reader in
                        Spacer()
                            .frame(width: reader.size.width * CGFloat(progress))
                            .background(.gray)
                            .animation(.default, value: progress)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
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
            .background(isDone ? (isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white) : .white.opacity(0.5))
        }
        // TODO FIXME
//        .onChange(of: initProgress.isDone) { newValue in
//            self.isDone = newValue
//        }
//        .onChange(of: initProgress.progress) { newValue in
//            self.progress = newValue
//        }
//        .onChange(of: machoElement) { newValue in
//            self.isDone = newValue.initProgress.isDone
//            self.progress = newValue.initProgress.progress
//        }
    }
    
    static func widthNeeded(for allMachoElements: [MachoBaseElement]) -> CGFloat {
        return allMachoElements.reduce(0) { partialResult, component in
            let attriString = NSAttributedString(string: component.title, attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)])
            let recommendedWidth = attriString.boundingRect(with: NSSize(width: 1000, height: 0), options: .usesLineFragmentOrigin).size.width
            return max(partialResult, recommendedWidth)
        } + 16
    }
    
}
