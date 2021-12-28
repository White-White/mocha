//
//  BinaryStore.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation
import SwiftUI

extension SmartDataContainer {
    var binaryStore: BinaryStore { BinaryStore(smartData) }
}

struct BinaryLine  {
    
    let data: Data
    let dataOffset: Int
    let hexDigits: Int
    
    init(data: Data, baseOffset: Int, hexDigits: Int) {
        self.data = data
        self.dataOffset = baseOffset
        self.hexDigits = hexDigits
    }
    
    func indexTagString() -> String {
        return String(format: "0x%0\(hexDigits)X", dataOffset)
    }
    
    func dataHexString(selectedRange: Range<Int>? = nil) -> AttributedString {
        var attriString = AttributedString((data.map { String(format: "%02X", $0) }).joined(separator: ""))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 14
        var container = AttributeContainer()
        container.paragraphStyle = paragraphStyle
        attriString.setAttributes(container)
        
        for index in 1..<(BinaryStore.NumberOfBytesPerLine / 4) {
            if let lowerBound = attriString.characters.index(attriString.startIndex, offsetBy: index * 8 - 1, limitedBy: attriString.endIndex),
               let upperBound = attriString.characters.index(attriString.startIndex, offsetBy: index * 8, limitedBy: attriString.endIndex) {
                if upperBound != attriString.endIndex {
                    attriString[lowerBound..<upperBound].kern = 4
                }
            }
        }
        
        if let selectedRange = selectedRange {
            // selectedRange is the range of bytes,
            // since attriString's been printed with %02X formate,
            // the coresponding selected range of characters in attriString should be (selectedRange.lower * 2)..<(selectedRange.upper * 2)
            let startDifference = (selectedRange.lowerBound - dataOffset) * 2
            let startOffset = max(0, startDifference)
            
            let endDifference = (selectedRange.upperBound - dataOffset) * 2
            let endOffset = min(BinaryStore.NumberOfBytesPerLine * 2, max(0, endDifference))
            
            if let lowerBound = attriString.characters.index(attriString.startIndex, offsetBy: startOffset, limitedBy: attriString.endIndex),
               let upperBound = attriString.characters.index(attriString.startIndex, offsetBy: endOffset, limitedBy: attriString.endIndex) {
                attriString[lowerBound..<upperBound].backgroundColor = Theme.selected
                attriString[lowerBound..<upperBound].foregroundColor = .white
            }
        }
        
        return attriString
    }
}

struct BinaryStore: Equatable {
    static func == (lhs: BinaryStore, rhs: BinaryStore) -> Bool {
        return lhs.data == rhs.data
    }
    
    static let NumberOfBytesPerLine = 24
    
    private let data: SmartData
    private let hexDigits: Int
    var numberOfBinaryLines: Int { data.count / BinaryStore.NumberOfBytesPerLine + (data.count % BinaryStore.NumberOfBytesPerLine != 0 ? 1 : 0) }
    
    init(_ data: SmartData) {
        self.data = data
        self.hexDigits = data.bestHexDigits
    }
    
    func binaryLine(at index: Int) -> BinaryLine {
        let lineData = data.truncated(from: index * BinaryStore.NumberOfBytesPerLine, maxLength: BinaryStore.NumberOfBytesPerLine)
        let line = BinaryLine(data: lineData.raw, baseOffset: data.startOffsetInMacho + index * BinaryStore.NumberOfBytesPerLine, hexDigits: hexDigits)
        return line
    }
    
    func binaryLineIndex(for range: Range<Int>?) -> Int? {
        if let lowerBound = range?.lowerBound, lowerBound >= data.startOffsetInMacho {
            return (lowerBound - data.startOffsetInMacho) / BinaryStore.NumberOfBytesPerLine
        }
        return nil
    }
}
