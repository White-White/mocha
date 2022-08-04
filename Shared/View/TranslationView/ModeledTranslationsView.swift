//
//  DefaultContentView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/23.
//

import SwiftUI

class TranslationSectionViewModel: Equatable, Identifiable {
    
    static func == (lhs: TranslationSectionViewModel, rhs: TranslationSectionViewModel) -> Bool {
        return lhs.dataRange == rhs.dataRange
    }
    let index: Int
    var id: Range<UInt64> { dataRange }
    let dataRange: Range<UInt64>
    let translationViewModels: [TranslationViewModel]
    
    init(translationViewModels: [TranslationViewModel], dataRange: Range<UInt64>, index: Int) {
        self.translationViewModels = translationViewModels
        self.dataRange = dataRange
        self.index = index
    }
}

class ModeledTranslationsViewModel {
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0) {
        willSet {
            self.translationSectionViewModels[selectedIndexPath.section].translationViewModels[selectedIndexPath.item].isSelected = false
        }
        didSet {
            self.translationSectionViewModels[selectedIndexPath.section].translationViewModels[selectedIndexPath.item].isSelected = true
        }
    }
    
    let translationSectionViewModels: [TranslationSectionViewModel]
    
    init(translationSections: [TranslationSection], machoComponentStartOffset: Int) {
        var nextStartOffset: UInt64 = UInt64(machoComponentStartOffset)
        var translationSectionViewModels: [TranslationSectionViewModel] = []
        for (sectionIndex, translationSection) in translationSections.enumerated() {
            let sectionStartOffset = nextStartOffset
            var translationViewModels: [TranslationViewModel] = []
            for (index, translation) in translationSection.translations.enumerated() {
                let translationStartOffset = nextStartOffset
                nextStartOffset += translation.bytesCount
                let translationViewModel = TranslationViewModel(translation,
                                                                range: translationStartOffset..<nextStartOffset,
                                                                index: index)
                translationViewModels.append(translationViewModel)
            }
            translationSectionViewModels.append(TranslationSectionViewModel(translationViewModels: translationViewModels,
                                                                            dataRange: sectionStartOffset..<nextStartOffset,
                                                                            index: sectionIndex))
        }
        self.translationSectionViewModels = translationSectionViewModels
        self.selectedTranslationViewModel?.isSelected = true
    }
    
    var selectedTranslationViewModel: TranslationViewModel? {
        guard selectedIndexPath.section < self.translationSectionViewModels.count else { return nil }
        let viewModels = self.translationSectionViewModels[selectedIndexPath.section].translationViewModels
        guard selectedIndexPath.item < viewModels.count else { return nil }
        return viewModels[selectedIndexPath.item]
    }

}

struct ModeledTranslationsView: View {
    
    let viewModel: ModeledTranslationsViewModel
    let machoViewState: MachoViewState
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.translationSectionViewModels) { sectionViewModel in
                    VStack(spacing: 0) {
                        ForEach(sectionViewModel.translationViewModels) { translationViewModel in
                            TranslationView(viewModel: translationViewModel)
                                .onTapGesture {
                                    self.viewModel.selectedIndexPath = IndexPath(item: translationViewModel.index, section: sectionViewModel.index)
                                    self.machoViewState.selectedDataRangeWrapper.value = viewModel.selectedTranslationViewModel?.range
                                }
                        }
                    }
                }
            }
        }
    }
    
    init(viewModel: ModeledTranslationsViewModel, machoViewState: MachoViewState) {
        self.viewModel = viewModel
        self.machoViewState = machoViewState
        viewModel.selectedIndexPath = IndexPath(item: 0, section: 0)
        machoViewState.selectedDataRangeWrapper.value = viewModel.selectedTranslationViewModel?.range
    }
}
