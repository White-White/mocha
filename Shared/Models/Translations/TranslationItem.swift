//
//  DataExplanation.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/7.
//

import Foundation
import SwiftUI

struct TranslationItemContent {
    
    let description: String?
    let explanation: String
    let extraExplanation: String?
    let monoSpaced: Bool
    
    init(description: String?, explanation: String, monoSpaced: Bool = false, extraExplanation: String? = nil) {
        self.description = description
        self.explanation = explanation
        self.extraExplanation = extraExplanation
        self.monoSpaced = monoSpaced
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
