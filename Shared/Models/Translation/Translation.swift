//
//  Translation.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/11.
//

import Foundation
import SwiftUI

enum ExplanationStyle {
    case realContent
    case extraDetail
    
    var selectable: Bool {
        switch self {
        case .realContent:
            return true
        case .extraDetail:
            return false
        }
    }
    
    var fontColor: Color {
        switch self {
        case .realContent:
            return .black
        case .extraDetail:
            return .gray
        }
    }
}

struct Translation {
    
    let description: String?
    let explanation: String
    let bytesCount: UInt64
    
    let explanationStyle: ExplanationStyle
    let extraDescription: String?
    let extraExplanation: String?
    
    let monoSpaced: Bool
    let hasDivider: Bool
    
    init(description: String?,
         explanation: String,
         bytesCount: Int,
         explanationStyle: ExplanationStyle = .realContent,
         extraDescription: String? = nil,
         extraExplanation: String? = nil,
         monoSpaced: Bool = false,
         hasDivider: Bool = false) {
        
        self.description = description
        self.explanation = explanation
        self.bytesCount = UInt64(bytesCount)
        
        self.explanationStyle = explanationStyle
        self.extraDescription = extraDescription
        self.extraExplanation = extraExplanation
        
        self.monoSpaced = monoSpaced
        self.hasDivider = hasDivider
    }
    
}

class TranslationGroup: Identifiable, Equatable {
    
    static func == (lhs: TranslationGroup, rhs: TranslationGroup) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    
    let startOffsetInMacho: UInt64
    var selectedIndex: Int = 0 {
        didSet {
            translationViewModels[oldValue].isSelected.toggle()
            translationViewModels[selectedIndex].isSelected.toggle()
        }
    }
    
    let translations: [Translation]
    let translationViewModels: [TranslationViewModel]
    
    init(_ translations: [Translation], startOffsetInMacho: Int) {
        self.translations = translations
        self.startOffsetInMacho = UInt64(startOffsetInMacho)
        var viewModels: [TranslationViewModel] = []
        var nextOffsetInMacho = self.startOffsetInMacho
        for (index, translation) in self.translations.enumerated() {
            viewModels.append(TranslationViewModel(translation,
                                                   range: nextOffsetInMacho..<(nextOffsetInMacho+translation.bytesCount),
                                                   indexInGroup: index,
                                                   isSelected: index == selectedIndex))
            nextOffsetInMacho += translation.bytesCount
        }
        self.translationViewModels = viewModels
    }
    
}
