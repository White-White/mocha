//
//  DataExplanation.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/7.
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

struct TranslationItemContent {
    
    let description: String?
    let explanation: String
    let explanationStyle: ExplanationStyle
    let extraDescription: String?
    let extraExplanation: String?
    let monoSpaced: Bool
    let hasDivider: Bool
    
    init(description: String?,
         explanation: String,
         explanationStyle: ExplanationStyle = .realContent,
         extraDescription: String? = nil,
         extraExplanation: String? = nil,
         monoSpaced: Bool = false,
         hasDivider: Bool = false) {
        
        self.description = description
        self.explanation = explanation
        self.explanationStyle = explanationStyle
        
        self.extraDescription = extraDescription
        self.extraExplanation = extraExplanation
        
        self.monoSpaced = monoSpaced
        self.hasDivider = hasDivider
    }
}

struct TranslationItem {
    
    var sourceDataRange: Range<Int>?
    let content: TranslationItemContent
    
    init(sourceDataRange: Range<Int>?, content: TranslationItemContent) {
        self.sourceDataRange = sourceDataRange
        self.content = content
    }
}
