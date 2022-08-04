//
//  MachoComponentWithTranslations.swift
//  mocha (macOS)
//
//  Created by white on 2022/8/3.
//

import Foundation

class MachoComponentWithTranslations: MachoComponent {
    
    var simpleTranslationsViewModel: SimpleTranslationsViewModel!
    
    override var hasMonsterSizedTranslations: Bool {
        return self.simpleTranslationsViewModel.translationViewModels.count > 100000
    }
    
    override func asyncInitializeTranslations() {
        self.simpleTranslationsViewModel = SimpleTranslationsViewModel(translations: self.createTranslations(), startOffsetInMacho: self.offsetInMacho)
    }
    
    func createTranslations() -> [Translation] { fatalError() }
    
}
