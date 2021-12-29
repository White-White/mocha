//
//  DataView.swift
//  mocha
//
//  Created by white on 2021/6/29.
//

import SwiftUI
import Foundation

struct HexLineView: View {
    
    @ObservedObject var binaryLine: LazyHexLine
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(binaryLine.startIndexString)
                .background(Color(.sRGB, red: 228/255, green: 228/255, blue: 228/255, opacity: 1))
                .font(.system(size: 12).monospaced())
                .foregroundColor(.secondary)
                .fixedSize()
            Text(binaryLine.dataHexString)
                .font(.system(size: 12).monospaced())
                .textSelection(.enabled)
                .fixedSize()
                .padding(.leading, 4)
        }
    }
}

struct HexView: View {
    
    @Binding var store: HexLineStore
    @Binding var selectedBinaryRange: Range<Int>?
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: true)  {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(store.binaryLines.indices, id: \.self) { index in
                            HexLineView(binaryLine: store.binaryLines[index])
                        }
                    }
                    .frame(width: 446)
                }
                .onChange(of: store, perform: { newValue in
                    scrollProxy.scrollTo(0, anchor: .top)
                })
                .onChange(of: selectedBinaryRange) { newValue in
                    store.updateLinesWith(selectedBytesRange: selectedBinaryRange)
                    if let selectedBinaryRange = selectedBinaryRange {
                        let targetElementIndexRange = store.targetIndexRange(for: selectedBinaryRange)
                        let targetElementIndex = (targetElementIndexRange.lowerBound + targetElementIndexRange.upperBound) / 2
                        withAnimation {
                            scrollProxy.scrollTo(targetElementIndex, anchor: .center)
                        }
                    }
                }
            }
        }
        .padding(4)
        .border(.separator, width: 1)
        .background(.white)
    }
}

