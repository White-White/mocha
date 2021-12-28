//
//  DataView.swift
//  mocha
//
//  Created by white on 2021/6/29.
//

import SwiftUI
import Foundation

struct HexView: View {
    
    @Binding var store: BinaryStore
    @Binding var selectedBinaryRange: Range<Int>?
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: true)  {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<store.numberOfBinaryLines, id: \.self) { index in
                            HStack(alignment: .center, spacing: 0) {
                                Text(store.binaryLine(at: index).indexTagString())
                                    .background(Color(.sRGB, red: 228/255, green: 228/255, blue: 228/255, opacity: 1))
                                    .font(.system(size: 12).monospaced())
                                    .foregroundColor(.secondary)
                                    .fixedSize()
                                Text(store.binaryLine(at: index).dataHexString(selectedRange: selectedBinaryRange))
                                    .background((index % 2 == 0) ? Color(red: 244.0/255, green: 245.0/255, blue: 245.0/255) : .white)
                                    .font(.system(size: 12).monospaced())
                                    .textSelection(.enabled)
                                    .fixedSize()
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
                .onChange(of: selectedBinaryRange, perform: { newValue in
                    if let binaryLineIndex = store.binaryLineIndex(for: selectedBinaryRange) {
                        withAnimation { scrollProxy.scrollTo(binaryLineIndex, anchor: .center) }
                    }
                })
                .onChange(of: store, perform: { newValue in
                    scrollProxy.scrollTo(0, anchor: .top)
                })
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(4)
        .border(.separator, width: 1)
        .background(.white)
    }
}

