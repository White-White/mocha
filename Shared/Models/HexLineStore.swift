//
//  BinaryStore.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation
import SwiftUI

class LazyHexLine: ObservableObject {
    
    static let lineHeight: CGFloat = 14
    
    let bytes: [UInt8]
    let fileOffset: Int
    let indexNumOfDigits: Int
    let isEvenLine: Bool
    @Published var selectedByteRange: Range<Int>?
    
    init(bytes: [UInt8], fileOffset: Int, indexNumOfDigits: Int, isEvenLine: Bool) {
        self.bytes = bytes
        self.fileOffset = fileOffset
        self.indexNumOfDigits = indexNumOfDigits
        self.isEvenLine = isEvenLine
    }
    
    var startIndexString: String {
        return String(format: "0x%0\(indexNumOfDigits)X", fileOffset)
    }
    
    var dataHexString: AttributedString {
        
        var string = (bytes.map { String(format: "%02X", $0) }).joined(separator: "")
        if bytes.count < HexLineStore.NumberOfBytesPerLine {
            let paddingLength = (HexLineStore.NumberOfBytesPerLine - bytes.count) * 2
            string.append(contentsOf: [Character](repeating: " ", count: paddingLength))
        }
        
        var attriString = AttributedString(string)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = LazyHexLine.lineHeight
        var container = AttributeContainer()
        container.paragraphStyle = paragraphStyle
        container.backgroundColor = (isEvenLine ? Color(red: 244.0/255, green: 245.0/255, blue: 245.0/255) : .white)
        
        attriString.setAttributes(container)
        
        for index in 1..<(HexLineStore.NumberOfBytesPerLine / 4) {
            if let lowerBound = attriString.characters.index(attriString.startIndex, offsetBy: index * 8 - 1, limitedBy: attriString.endIndex),
               let upperBound = attriString.characters.index(attriString.startIndex, offsetBy: index * 8, limitedBy: attriString.endIndex) {
                if upperBound != attriString.endIndex {
                    attriString[lowerBound..<upperBound].kern = 4
                }
            }
        }
        
        if let selectedRange = selectedByteRange {
            if let lowerBound = attriString.characters.index(attriString.startIndex, offsetBy: selectedRange.lowerBound, limitedBy: attriString.endIndex),
               let upperBound = attriString.characters.index(attriString.startIndex, offsetBy: selectedRange.upperBound, limitedBy: attriString.endIndex) {
                attriString[lowerBound..<upperBound].backgroundColor = Theme.selected
                attriString[lowerBound..<upperBound].foregroundColor = .white
            }
        }
        
        return attriString
    }
}

class HexLineStore: Equatable {
    
    static func == (lhs: HexLineStore, rhs: HexLineStore) -> Bool {
        return lhs.data == rhs.data
    }
    
    static let NumberOfBytesPerLine = 24
    
    private let data: DataSlice
    private let hexDigits: Int
    
    let binaryLines: [LazyHexLine]
    private var selectedBytesRange: Range<Int>?
    
    init(_ data: DataSlice) {
        self.data = data
        self.hexDigits = data.preferredNumberOfHexDigits
        
        var numberOfBinaryLines = data.count / HexLineStore.NumberOfBytesPerLine
        if data.count % HexLineStore.NumberOfBytesPerLine != 0  { numberOfBinaryLines += 1 }
        
        var binaryLines: [LazyHexLine] = []
        for index in 0..<numberOfBinaryLines {
            let lineData = data.truncated(from: index * HexLineStore.NumberOfBytesPerLine,
                                          maxLength: HexLineStore.NumberOfBytesPerLine)
            
            let line = LazyHexLine(bytes: [UInt8](lineData.raw),
                                   fileOffset: data.startIndex + index * HexLineStore.NumberOfBytesPerLine,
                                   indexNumOfDigits: hexDigits,
                                   isEvenLine: index & 0x1 == 0)
            
            binaryLines.append(line)
        }
        
        self.binaryLines = binaryLines
    }
    
    func targetIndexRange(for selectedBytesRange: Range<Int>) -> ClosedRange<Int> {
        let startDifference = max(0, selectedBytesRange.lowerBound - data.startIndex)
        let endDifference = max(0, selectedBytesRange.upperBound - data.startIndex)
        let startIndex = startDifference / HexLineStore.NumberOfBytesPerLine
        var endIndex = endDifference / HexLineStore.NumberOfBytesPerLine
        if endDifference % HexLineStore.NumberOfBytesPerLine == 0 { endIndex -= 1 }
        return startIndex...endIndex
    }
    
    func updateLinesWith(selectedBytesRange: Range<Int>?) {
        if let previoutsSelectedBytesRange = self.selectedBytesRange {
            for index in targetIndexRange(for: previoutsSelectedBytesRange) {
                binaryLines[index].selectedByteRange = nil
            }
        }
        
        if let selectedBytesRange = selectedBytesRange {
            for index in targetIndexRange(for: selectedBytesRange) {
                let startDifference = max(0, (selectedBytesRange.lowerBound - binaryLines[index].fileOffset) * 2)
                var endDifference = max(0, (selectedBytesRange.upperBound - binaryLines[index].fileOffset) * 2)
                endDifference = min(HexLineStore.NumberOfBytesPerLine * 2, endDifference)
                
                let targetRangeLower = startDifference % (HexLineStore.NumberOfBytesPerLine * 2)
                var targetRangeHigher = endDifference % (HexLineStore.NumberOfBytesPerLine * 2)
                if targetRangeHigher == 0 { targetRangeHigher = HexLineStore.NumberOfBytesPerLine * 2 }
                
                binaryLines[index].selectedByteRange = targetRangeLower..<targetRangeHigher
            }
        }
        
        self.selectedBytesRange = selectedBytesRange
    }
}
