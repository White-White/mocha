//
//  DataExplanation.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/7.
//

import Foundation
import SwiftUI

protocol TranslationStoreDataSource {
    var numberOfTranslationSections: Int { get }
    func translationSection(at index: Int) -> TransSection
}

struct TranslationStore: Equatable {
    static func == (lhs: TranslationStore, rhs: TranslationStore) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    let dataSource: TranslationStoreDataSource
}

struct Readable {
    let description: String?
    let explanation: String
}

struct TransTerm {
    var range: Range<Int>?
    let readable: Readable
}

class TransSection {
    
    let title: String?
    let baseIndex: Int
    
    private var translated: Int = 0
    private(set) var terms: [TransTerm] = []
    
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
            self.terms.append(TransTerm(range: rangeConsideringBaseOffset, readable: readableGenerator()))
        } else {
            self.terms.append(TransTerm(range: nil, readable: readableGenerator()))
        }
    }
}
