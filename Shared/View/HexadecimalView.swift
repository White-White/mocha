//
//  DataView.swift
//  mocha
//
//  Created by white on 2021/6/29.
//

import SwiftUI

struct HexadecimalView: View {
    
    @ObservedObject var viewModel: HexadecimalViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: true)  {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        self.linesView(by: viewModel.linesViewModels)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .onChange(of: viewModel.visiableHighlightedLineIndex, perform: { newValue in
                    if let visiableLineIndex = newValue {
                        withAnimation {
                            scrollProxy.scrollTo(viewModel.linesViewModels[visiableLineIndex].line.offsetInMacho, anchor: .center)
                        }
                    }
                })
                .onChange(of: viewModel) { newValue in
                    if let firstLienOffsetInMacho = newValue.linesViewModels.first?.line.offsetInMacho {
                        scrollProxy.scrollTo(firstLienOffsetInMacho, anchor: .top)
                }
            }
        }
        .padding(4)
        .border(.separator, width: 1)
        .background(.white)
    }
    
    func linesView(by viewModels: [HexadecimalLineViewModel]) -> some View {
        ForEach(viewModel.linesViewModels, id: \.line.offsetInMacho) { lineViewModel in
            HexadecimalLineView(viewModel: lineViewModel)
        }
    }
    
}

