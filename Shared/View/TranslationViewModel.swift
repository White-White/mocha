//
//  TranslationViewModel.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/30.
//

import SwiftUI

protocol TranslationViewModelObserver {
    func onChange(visiableDataRange: Range<Int>)
    func onChange(selectedItemViewModel: TranslationItemViewModel?, oldValue:TranslationItemViewModel?)
}

class TranslationViewModel: ObservableObject, Equatable {
    static func == (lhs: TranslationViewModel, rhs: TranslationViewModel) -> Bool {
        return lhs.machoComponent == rhs.machoComponent
    }
    
    static let NumberOfSectionsInPage = 128
    
    let minPage: Int
    let maxPage: Int
    var lastPage: Int?
    
    @Published var currentPage: Int {
        didSet {
            self.translationItemViewModels = TranslationViewModel.translationItems(machoComponent: machoComponent, at: currentPage)
            self.observers.forEach { $0.onChange(visiableDataRange: visiableDataRange) }
            self.lastPage = oldValue
            self.didSelect(self.translationItemViewModels.first?.first)
        }
    }
    
    var visiableDataRange: Range<Int> {
        if let lowerBound = self.translationItemViewModels.first?.first?.item.sourceDataRange?.lowerBound,
           let upperBound = self.translationItemViewModels.last?.last?.item.sourceDataRange?.upperBound {
            return lowerBound..<upperBound
        }
        return machoComponent.dataSlice.startOffset..<(machoComponent.dataSlice.startOffset+machoComponent.dataSlice.count)
    }
    
    let machoComponent: MachoComponent
    var observers: [TranslationViewModelObserver] = []
    
    var lastSelectedItemViewModel: TranslationItemViewModel? = nil {
        didSet {
            self.observers.forEach { $0.onChange(selectedItemViewModel: lastSelectedItemViewModel, oldValue: oldValue) }
        }
    }
    @Published var translationItemViewModels: [[TranslationItemViewModel]]
    
    init(_ machoComponent: MachoComponent, minPage: Int = 0) {
        self.minPage = minPage
        self.maxPage = machoComponent.numberOfTranslationSections() / TranslationViewModel.NumberOfSectionsInPage
        self.currentPage = minPage
        self.machoComponent = machoComponent
        
        let viewModels = TranslationViewModel.translationItems(machoComponent: machoComponent, at: minPage)
        self.translationItemViewModels = viewModels
        self.didSelect(viewModels.first?.first)
    }
    
    func didSelect(_ viewModel: TranslationItemViewModel?) {
        if let viewModel = viewModel {
            if !viewModel.item.content.explanationStyle.selectable { return }
            viewModel.isSelected = true
            self.lastSelectedItemViewModel?.isSelected = false
            self.lastSelectedItemViewModel = viewModel
        }
    }
    
    static func translationItems(machoComponent: MachoComponent, at currentPage: Int) -> [[TranslationItemViewModel]] {
        var translationItemViewModels: [[TranslationItemViewModel]] = []
        let sectionStartIndex = min(currentPage * TranslationViewModel.NumberOfSectionsInPage, machoComponent.numberOfTranslationSections() - 1)
        let sectionEndIndex = min(sectionStartIndex + TranslationViewModel.NumberOfSectionsInPage, machoComponent.numberOfTranslationSections())
        for sectionIndex in sectionStartIndex..<sectionEndIndex {
            let numberOfItems = machoComponent.numberOfTranslationItems(at: sectionIndex)
            let translationItems = (0..<numberOfItems).map { machoComponent.translationItem(at: IndexPath(item: $0, section: sectionIndex)) }
            let viewModels = translationItems.map { TranslationItemViewModel($0) }
            translationItemViewModels.append(viewModels)
        }
        return translationItemViewModels
    }
}
