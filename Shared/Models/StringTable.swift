//
//  StringTable.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation

class StringTable: SmartDataContainer, TranslationStoreDataSource {
    
    let smartData: SmartData
    var primaryName: String { "String Table" }
    var secondaryName: String { "String Table" }
    
    init(_ stringTableData: SmartData) {
        self.smartData = stringTableData
    }
    
    lazy var cStringRanges: [Range<Int>] = {
        let rawData = smartData.raw
        var ranges: [Range<Int>] = []
        var lastNullCharIndex: Int? // index of last null char ( "\0" )
        for (index, byte) in rawData.enumerated() {
            guard byte == 0 else { continue } // find null characters
            let currentIndex = index
            let lastIndex = lastNullCharIndex ?? -1
            if currentIndex - lastIndex == 1 {
                // skip continuous \0
                lastNullCharIndex = currentIndex
                continue
            }
            let dataStartIndex = lastIndex + 1 // lastIdnex points to last null, ignore
            lastNullCharIndex = currentIndex
            ranges.append(dataStartIndex..<currentIndex)
        }
        return ranges
    }()
    
    var numberOfTranslationSections: Int { cStringRanges.count }
    
    func translationSection(at index: Int) -> TransSection {
        if index >= cStringRanges.count { fatalError() }
        let range = cStringRanges[index]
        let section = TransSection(baseIndex: range.lowerBound + smartData.startOffsetInMacho)
        let rawStringData = smartData.truncated(from: range.lowerBound, length: range.upperBound - range.lowerBound).raw
        let readable: Readable
        if let string = String(data: rawStringData, encoding: .utf8) {
            readable = Readable(description: "UTF8 encoded string", explanation: string.replacingOccurrences(of: "\n", with: "\\n"))
        } else {
            readable = Readable(description: "Invalid utf8 encoded", explanation: "🙅‍♂️ Invalid utf8 string")
        }
        section.translateNext(rawStringData.count) { readable }
        return section
    }
}
