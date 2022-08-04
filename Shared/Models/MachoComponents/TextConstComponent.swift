//
//  TextConstComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/29.
//

import Foundation

struct TextConstModel {
    let targetOffsetInMacho: Int
    let translations: [Translation]
}

protocol TextConstParser: MachoComponent {
    var textConstModel: [TextConstModel] { get }
}

class TextConstComponent: ModeledTranslationComponent {
    
    private(set) var parsers: [TextConstParser] = []
    let serialQueue = DispatchQueue(label: "TextConstComponent")
    
    override var translationInitDependencies: [MachoComponent?] { self.parsers }
    
    override func createTranslationSections() -> [TranslationSection] {
        let textConstModels = self.parsers.flatMap { $0.textConstModel }
        return textConstModels.map { TranslationSection(translations: $0.translations) }
    }
    
    func addParser(_ parser: TextConstParser) {
        self.parsers.append(parser)
    }
    
}


