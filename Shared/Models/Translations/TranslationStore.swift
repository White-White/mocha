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

class TranslationItemContainer {

    let machoDataSlice: DataSlice
    private(set) var translated: Int = 0
    private(set) var items: [TranslationItem] = []

    init(machoDataSlice: DataSlice, sectionTitle: String? = nil) {
        self.machoDataSlice = machoDataSlice
    }

    func translate<T>(next straddle: Straddle, dataInterpreter: (Data) -> T, itemContentGenerator: (T) -> TranslationItemContent) -> T {
        defer { translated += straddle.raw }
        let rawData = self.machoDataSlice.truncated(from: translated, length: straddle.raw).raw
        let rawDataAbsoluteRange = machoDataSlice.startIndex+translated..<machoDataSlice.startIndex+translated+straddle.raw
        let interpreted: T = dataInterpreter(rawData)
        items.append(TranslationItem(sourceDataRange: rawDataAbsoluteRange, content: itemContentGenerator(interpreted)))
        return interpreted
    }
    
    func skip(_ straddle: Straddle) -> Self {
        translated += straddle.raw
        return self
    }
    
    func insert(_ itemContent: TranslationItemContent, forRange range: Range<Int>, at index: Int = .zero) {
        let item = TranslationItem(sourceDataRange: range, content: itemContent)
        items.insert(item, at: index)
    }
    
    func append(_ itemContent: TranslationItemContent, forRange range: Range<Int>) {
        let item = TranslationItem(sourceDataRange: range, content: itemContent)
        items.append(item)
    }
}

struct DataInterpreterPreset {
    static func UInt32(_ data: Data) -> Swift.UInt32 {
        return data.UInt32
    }
}
