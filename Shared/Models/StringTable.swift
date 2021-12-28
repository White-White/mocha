//
//  StringTable.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation

class StringTable: SmartDataContainer, TranslationStore {
    
    let smartData: SmartData
    
    init(_ stringTableData: SmartData) {
        self.smartData = stringTableData
    }
    
    lazy var cStringRanges: [Range<Int>] = {
        var ranges: [Range<Int>] = []
        var lastNullCharIndex: Int? // index of last null char ( "\0" )
        for (index, byte) in smartData.raw.enumerated() {
            guard byte == 0 else { continue } // find null characters
            let currentIndex = index
            let lastIndex = lastNullCharIndex ?? -1
            if currentIndex - lastIndex == 1 {
                // skip continuous \0
                lastNullCharIndex = currentIndex
                continue
            }
            let dataStartIndex = lastIndex + 1 // lastIdnex points to last null, ignore
            let dataEndIndex = currentIndex - 1 // also ignore the last null
            lastNullCharIndex = currentIndex
            ranges.append(dataStartIndex..<dataEndIndex)
        }
        return ranges
    }()
    
    var numberOfTranslationSections: Int { cStringRanges.count }
    
    func translationSection(at index: Int) -> TranslationSection {
        if index >= cStringRanges.count { fatalError() }
        let range = cStringRanges[index]
        let section = TranslationSection(baseIndex: range.lowerBound)
        if let string = String(data: smartData.raw.select(from: range.lowerBound, length: range.upperBound - range.lowerBound), encoding: .utf8) {
            section.addTranslation(forRange: range) { Readable(description: "UTF8 encoded string", explanation: string.replacingOccurrences(of: "\n", with: "\\n")) }
        } else {
            section.addTranslation(forRange: range) { Readable(description: "Invalid utf8 encoded", explanation: "🙅‍♂️ Invalid utf8 string") }
        }
        return section
    }
}
