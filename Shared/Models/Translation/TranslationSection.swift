//
//  TranslationSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/23.
//

import Foundation

struct TranslationSection {
    
    let byteCount: UInt64
    let translations: [Translation]
    
    init(translations: [Translation]) {
        self.translations = translations
        self.byteCount = translations.reduce(0) { $0 + $1.bytesCount }
    }
    
}
