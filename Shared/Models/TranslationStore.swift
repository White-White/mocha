//
//  DataExplanation.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/7.
//

import Foundation
import SwiftUI

protocol TranslationStore {
    var numberOfTranslationSections: Int { get }
    func translationSection(at index: Int) -> TranslationSection
}

struct Readable {
    let description: String?
    let explanation: String
}

struct TranslationTerm: Equatable {
    static func == (lhs: TranslationTerm, rhs: TranslationTerm) -> Bool {
        return lhs.range == rhs.range
    }
    
    var range: Range<Int>?
    let readable: Readable
    
    init(range: Range<Int>?, readable: Readable) {
        self.range = range
        self.readable = readable
    }
}

class TranslationSection {
    
    let title: String?
    let baseIndex: Int
    
    private var translated: Int = 0
    private(set) var terms: [TranslationTerm] = []
    
    init(baseIndex: Int, title: String? = nil) {
        self.baseIndex = baseIndex
        self.title = title
    }
    
    func ignore(_ count: Int) { translated += count }
    
    func translateNextDoubleWord(_ readableGenerator: @escaping () -> Readable) { translateNext(4, readableGenerator) }

    func translateNext(_ count: Int, _ readableGenerator: @escaping () -> Readable) {
        defer { translated += count }
        let startIndex = translated
        let endIndex = startIndex + count
        self.addTranslation(forRange: startIndex..<endIndex, readableGenerator: readableGenerator)
    }
    
    func addTranslation(forRange range: Range<Int>?, readableGenerator: @escaping () -> Readable) {
        if let range = range {
            let rangeConsideringBaseOffset = (range.lowerBound + baseIndex)..<(range.upperBound + baseIndex)
            self.terms.append(TranslationTerm(range: rangeConsideringBaseOffset, readable: readableGenerator()))
        } else {
            self.terms.append(TranslationTerm(range: nil, readable: readableGenerator()))
        }
    }
}
