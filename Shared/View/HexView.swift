//
//  DataView.swift
//  mocha
//
//  Created by white on 2021/6/29.
//

import SwiftUI
import Foundation
import Introspect

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

class HexViewHelper {
    var rawScrollView: NSScrollView?
}

struct HexView: View {
    
    @Binding var store: HexLineStore
    @Binding var sourceDataRangeOfSelecteditem: Range<Int>?
    let helper = HexViewHelper()
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: true)  {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(store.binaryLines.indices, id: \.self) { index in
                            HexLineView(binaryLine: store.binaryLines[index])
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .onChange(of: store, perform: { newValue in
                    scrollProxy.scrollTo(0, anchor: .top)
                })
                .onChange(of: sourceDataRangeOfSelecteditem) { newValue in
                    store.updateLinesWith(selectedBytesRange: sourceDataRangeOfSelecteditem)
                    if let sourceDataRangeOfSelecteditem = sourceDataRangeOfSelecteditem {
                        let targetElementIndexRange = store.targetIndexRange(for: sourceDataRangeOfSelecteditem)
                        let targetElementIndex = (targetElementIndexRange.lowerBound + targetElementIndexRange.upperBound) / 2
                        if let visibleRect = helper.rawScrollView?.documentView?.visibleRect {
                            let beginIndex = Int(visibleRect.origin.y / (LazyHexLine.lineHeight))
                            // line height is 14, but + 1 here to make 'visible' range smaller
                            let endIndex = Int(visibleRect.maxY / (LazyHexLine.lineHeight + 1))
                            if targetElementIndex < beginIndex || targetElementIndex > endIndex {
                                withAnimation {
                                    scrollProxy.scrollTo(targetElementIndex, anchor: .center)
                                }
                            }
                        }
                    }
                }
                .introspectScrollView { scrollView in
                    helper.rawScrollView = scrollView
                }
            }
        }
        .padding(4)
        .border(.separator, width: 1)
        .background(.white)
    }
}

