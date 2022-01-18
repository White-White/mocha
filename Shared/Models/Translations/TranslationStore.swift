//
//  TranslationItemContainer.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/9.
//

import Foundation

class TranslationStore {

    let machoDataSlice: DataSlice
    private(set) var translated: Int = 0
    private(set) var items: [TranslationItem] = []

    init(machoDataSlice: DataSlice) {
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
