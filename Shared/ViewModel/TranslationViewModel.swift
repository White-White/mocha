//
//  TranslationViewModel.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/18.
//

import Foundation

class TranslationViewModel: ObservableObject {
    
    @Published var isSelected: Bool
    let range: Range<UInt64>
    let translation: Translation
    let indexInGroup: Int
    
    init(_ translation: Translation, range: Range<UInt64>, indexInGroup: Int, isSelected: Bool) {
        self.translation = translation
        self.range =  range
        self.isSelected = isSelected
        self.indexInGroup = indexInGroup
    }
    
}
