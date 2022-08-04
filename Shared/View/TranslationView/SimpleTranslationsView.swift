//
//  SimpleTranslationsView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/27.
//

import SwiftUI

class SimpleTranslationsViewModel {
    
    var selectedIndex: Int = 0 {
        willSet {
            self.translationViewModels[self.selectedIndex].isSelected = false
        }
        didSet {
            self.translationViewModels[self.selectedIndex].isSelected = true
        }
    }
    
    let translationViewModels: [TranslationViewModel]
    
    init(translations: [Translation], startOffsetInMacho: Int) {
        var nextStartOffset: UInt64 = UInt64(startOffsetInMacho)
        var translationViewModels: [TranslationViewModel] = []
        for (index, translation) in translations.enumerated() {
            let translationStartOffset = nextStartOffset
            nextStartOffset += translation.bytesCount
            let translationViewModel = TranslationViewModel(translation,
                                                            range: translationStartOffset..<nextStartOffset,
                                                            index: index)
            translationViewModels.append(translationViewModel)
        }
        self.translationViewModels = translationViewModels
        self.selectedTranslationViewModel.isSelected = true
    }
    
    var selectedTranslationViewModel: TranslationViewModel {
        return self.translationViewModels[self.selectedIndex]
    }
    
}

struct SimpleTranslationsView: View {
    
    let viewModel: SimpleTranslationsViewModel
    let machoViewState: MachoViewState
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.translationViewModels) { translationViewModel in
                    TranslationView(viewModel: translationViewModel)
                        .onTapGesture {
                            self.machoViewState.selectedDataRangeWrapper.value = translationViewModel.range
                            self.viewModel.selectedIndex = translationViewModel.index
                        }
                }
            }
        }
    }
    
    init(viewModel: SimpleTranslationsViewModel, machoViewState: MachoViewState) {
        self.viewModel = viewModel
        self.machoViewState = machoViewState
        viewModel.selectedIndex = 0
        machoViewState.selectedDataRangeWrapper.value = viewModel.selectedTranslationViewModel.range
    }
    
}
