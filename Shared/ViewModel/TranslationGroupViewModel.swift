//
//  TranlationGroupViewModel.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/18.
//

import Foundation

class TranslationGroupViewModel: Equatable {
    
    static func == (lhs: TranslationGroupViewModel, rhs: TranslationGroupViewModel) -> Bool {
        return lhs.dataRangeAllTranslation == rhs.dataRangeAllTranslation
    }
    
    var selectedIndex: Int = 0 {
        didSet {
            translationViewModels[oldValue].isSelected.toggle()
            translationViewModels[selectedIndex].isSelected.toggle()
        }
    }
    
    var translationViewModels: [TranslationViewModel]
    
    let dataRangeFirstTranslation: Range<UInt64>?
    let dataRangeAllTranslation: Range<UInt64>
    
    init(_ machoComponent: MachoComponent) {
        let startOffsetInMacho = machoComponent.offsetInMacho
        let translations = machoComponent.translations
        
        var translationViewModels: [TranslationViewModel] = []
        var nextOffsetInMacho = UInt64(startOffsetInMacho)
        for (index, translation) in translations.enumerated() {
            translationViewModels.append(TranslationViewModel(translation,
                                                              range: nextOffsetInMacho..<(nextOffsetInMacho+translation.bytesCount),
                                                              indexInGroup: index,
                                                              isSelected: index == selectedIndex))
            nextOffsetInMacho += translation.bytesCount
        }
        self.translationViewModels = translationViewModels
        
        self.dataRangeFirstTranslation = translationViewModels.first?.range
        self.dataRangeAllTranslation = UInt64(startOffsetInMacho)..<UInt64(startOffsetInMacho + machoComponent.dataSize)
    }
}
