//
//  DataExplanation.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/7.
//

import Foundation
import SwiftUI

protocol BinaryTranslationStoreGenerator {
    func binaryTranslationStore() -> BinaryTranslationStore
}

struct BinaryLine  {
    
    let data: Data
    let dataOffset: Int
    
    init(data: Data, baseOffset: Int) {
        self.data = data
        self.dataOffset = baseOffset
    }
    
    func indexTagString(with digitsCount: Int) -> String {
        return String(format: "0x%0\(digitsCount)X", dataOffset)
    }
    
    func dataHexString(selectedRange: Range<Int>? = nil) -> AttributedString {
        var attriString = AttributedString((data.map { String(format: "%02X", $0) }).joined(separator: ""))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 14
        var container = AttributeContainer()
        container.paragraphStyle = paragraphStyle
        attriString.setAttributes(container)
        
        for index in 1..<(BinaryTranslationStore.NumberOfBytesPerLine / 4) {
            if let lowerBound = attriString.characters.index(attriString.startIndex, offsetBy: index * 8 - 1, limitedBy: attriString.endIndex),
               let upperBound = attriString.characters.index(attriString.startIndex, offsetBy: index * 8, limitedBy: attriString.endIndex) {
                attriString[lowerBound..<upperBound].kern = 4
            }
        }
        
        if let selectedRange = selectedRange {
            // selectedRange is the range of bytes,
            // since attriString's been printed with %02X formate,
            // the coresponding selected range of characters in attriString should be (selectedRange.lower * 2)..<(selectedRange.upper * 2)
            let startDifference = (selectedRange.lowerBound - dataOffset) * 2
            let startOffset = max(0, startDifference)
            
            let endDifference = (selectedRange.upperBound - dataOffset) * 2
            let endOffset = min(BinaryTranslationStore.NumberOfBytesPerLine * 2, max(0, endDifference))
            
            if let lowerBound = attriString.characters.index(attriString.startIndex, offsetBy: startOffset, limitedBy: attriString.endIndex),
               let upperBound = attriString.characters.index(attriString.startIndex, offsetBy: endOffset, limitedBy: attriString.endIndex) {
                attriString[lowerBound..<upperBound].backgroundColor = Theme.selected
                attriString[lowerBound..<upperBound].foregroundColor = .white
            }
        }
        
        return attriString
    }
}

struct Readable {
    
    let dividerName: String?
    let description: String?
    let explanation: String
    
    init(description: String? = nil, explanation: String?, dividerName: String? = nil) {
        self.description = description
        self.explanation = explanation ?? "Unknown how to explain yet. Fixme: "
        self.dividerName = dividerName
    }
}

struct LazyTranslation: Equatable {
    static func == (lhs: LazyTranslation, rhs: LazyTranslation) -> Bool {
        return lhs.id == rhs.id
    }
    
    typealias ReadableGenerator = () -> Readable
    
    let id = UUID()
    let readableGenerator: ReadableGenerator
    let range: Range<Int>?
    
    init(range: Range<Int>?, readableGenerator: @escaping ReadableGenerator) {
        self.range = range
        self.readableGenerator = readableGenerator
    }
}

struct BinaryTranslationStore {
    
    static let NumberOfBytesPerLine: Int = 24
    
    private var data: SmartData
    private let baseDataOffset: Int
    private(set) var numberOfBinaryLines: Int
    private var translated: Int = 0
    
    var numberOfTranslations: Int { translations.count }
    private var translations: [LazyTranslation] = []
    
    init(data: SmartData, baseDataOffset: Int) {
        self.data = data
        self.baseDataOffset = baseDataOffset
        self.numberOfBinaryLines = BinaryTranslationStore.numberOfLines(from: data.count)
    }
    
    static func numberOfLines(from bytesCount: Int) -> Int {
        var numberOfLines = bytesCount / BinaryTranslationStore.NumberOfBytesPerLine
        if (bytesCount % BinaryTranslationStore.NumberOfBytesPerLine) != 0 { numberOfLines += 1 }
        return numberOfLines
    }
    
    func binaryLine(at index: Int) -> BinaryLine {
        let lineData = data.select(from: index * BinaryTranslationStore.NumberOfBytesPerLine, maxLength: BinaryTranslationStore.NumberOfBytesPerLine)
        let line = BinaryLine(data: lineData.realData, baseOffset: baseDataOffset + index * BinaryTranslationStore.NumberOfBytesPerLine)
        return line
    }
    
    func translation(at index: Int) -> LazyTranslation { translations[index] }
    
    mutating func translateNextWord(_ readableGenerator: @escaping LazyTranslation.ReadableGenerator) {
        translateNext(2, readableGenerator: readableGenerator)
    }
    
    mutating func translateNextDoubleWord(_ readableGenerator: @escaping LazyTranslation.ReadableGenerator) {
        translateNext(4, readableGenerator: readableGenerator)
    }
    
    mutating func translateNextQuadWord(_ readableGenerator: @escaping LazyTranslation.ReadableGenerator) {
        translateNext(8, readableGenerator: readableGenerator)
    }
    
    mutating func translateNext(_ count: Int, readableGenerator: @escaping LazyTranslation.ReadableGenerator) {
        defer { translated += count }
        let startIndex = translated
        let endIndex = startIndex + count
        self.addTranslation(forRange: startIndex..<endIndex, readableGenerator: readableGenerator)
    }
    
    mutating func addTranslation(forRange range: Range<Int>?, readableGenerator: @escaping LazyTranslation.ReadableGenerator) {
        if let range = range {
            let rangeConsideringBaseOffset = (range.lowerBound + baseDataOffset)..<(range.upperBound + baseDataOffset)
            self.translations.append(LazyTranslation(range: rangeConsideringBaseOffset, readableGenerator: readableGenerator))
        } else {
            self.translations.append(LazyTranslation(range: nil, readableGenerator: readableGenerator))
        }
    }
    
    func binaryLineIndex(for translation: LazyTranslation) -> Int? {
        if let lowerBound = translation.range?.lowerBound, lowerBound >= baseDataOffset {
            return (lowerBound - baseDataOffset) / BinaryTranslationStore.NumberOfBytesPerLine
        }
        return nil
    }
    
    mutating func ignore(_ count: Int) { translated += count }
    
    mutating func merge(with anotherStore: BinaryTranslationStore) {
        guard data.sameSource(with: anotherStore.data) else { fatalError() }
        
        // to merge one store with another, the data of nextStore must be consectutive with self's data
        // that is, self's data count plus self's lineTagStartIndex must be the nextStore's lineTagStartIndex
        guard baseDataOffset + data.count == anotherStore.baseDataOffset else { fatalError() }
        
        // for newly added translations, it's range needs to be updated
        self.translations += anotherStore.translations
        
        // since they are all SmartData and have the same Data base,
        // all we need to do is to extend the length property of current store
        self.data.extend(length: anotherStore.data.count)
        
        // update number of lines
        self.numberOfBinaryLines = BinaryTranslationStore.numberOfLines(from: self.data.count)
    }
}
