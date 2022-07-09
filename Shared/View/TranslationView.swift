//
//  TranslationView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import SwiftUI

struct TranslationView: View {
    
    @Binding var selectedRange: Range<UInt64>
    @ObservedObject var translationViewModel: TranslationViewModel
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true)  {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(translationViewModel.translationItemViewModels.indices, id: \.self) { index in
                        ForEach(translationViewModel.translationItemViewModels[index]) { viewModel in
                            VStack(alignment: .leading, spacing: 0) {
                                TranslationItemView(viewModel: viewModel)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedRange = viewModel.item.sourceDataRange
                                        translationViewModel.didSelect(viewModel)
                                    }
                                if viewModel.item.content.hasDivider { Divider() }
                            }
                        }
                    }
                }
                .padding(4)
            }
            .background(.white)
            .border(.separator, width: 1)
            .frame(minWidth: 400)
            .onChange(of: translationViewModel) { newValue in
                scrollProxy.scrollTo(0, anchor: nil)
            }
            .onChange(of: translationViewModel.currentPage) { newValue in
                scrollProxy.scrollTo(0, anchor: nil)
            }
        }
    }
    
}

