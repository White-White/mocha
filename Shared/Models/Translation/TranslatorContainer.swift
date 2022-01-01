//
//  TranslatorContainer.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

protocol TranslatorContainerGenerator {
    func makeTranslatorContainers(from machoData: SmartData, is64Bit: Bool) -> [TranslatorContainer]
}

class TranslatorContainer: SmartDataContainer, TranslationStoreDataSource {
    
    let smartData: SmartData
    let is64Bit: Bool
    let translator: Translator
    let primaryName: String
    let secondaryName: String
    
    init(_ data: SmartData, is64Bit: Bool, translatorType: Translator.Type, primaryName: String, secondaryName: String) {
        self.smartData = data
        self.is64Bit = is64Bit
        self.translator = translatorType.init(data, is64Bit: is64Bit)
        self.primaryName = primaryName
        self.secondaryName = secondaryName
    }
    
    var numberOfTranslationSections: Int {
        return self.translator.numberOfTransSections
    }
    
    func translationSection(at index: Int) -> TransSection {
        return self.translator.transSection(at: index)
    }
    
    func preload() {
        self.translator.preload()
    }
}
