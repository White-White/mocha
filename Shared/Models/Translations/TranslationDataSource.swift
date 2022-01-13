//
//  Protocols.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/10.
//

import Foundation

protocol TranslationDataSource {
    var numberOfTranslationItems: Int { get }
    func translationItem(at index: Int) -> TranslationItem
}
