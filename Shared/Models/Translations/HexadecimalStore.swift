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
    
    lazy var bytes: [UInt8] = {
        self.store!.bytes(at: self.offset, length: HexadecimalStore.NumberOfBytesPerLine)
    }()
    
    fileprivate weak var store: HexadecimalStore?
    let offset: Int
    let fileOffset: Int
    let indexNumOfDigits: Int
    let isEvenLine: Bool
    @Published var selectedByteRange: Range<Int>?
    
    fileprivate init(offset: Int, baseOffset: Int, indexNumOfDigits: Int, isEvenLine: Bool) {
        self.offset = offset
        self.fileOffset = offset + baseOffset
        self.indexNumOfDigits = indexNumOfDigits
        self.isEvenLine = isEvenLine
    }
    
    var startIndexString: String {
        return String(format: "0x%0\(indexNumOfDigits)X", fileOffset)
    }
    
    var dataHexString: AttributedString {
        
        let string: String
        if bytes.count < HexadecimalStore.NumberOfBytesPerLine {
            var tmpString = (bytes.map { String(format: "%02X", $0) }).joined(separator: "")
            let paddingLength = (HexadecimalStore.NumberOfBytesPerLine - bytes.count) * 2
            tmpString.append(contentsOf: [Character](repeating: " ", count: paddingLength))
            string = tmpString
        } else {
            string = String(format:
                                    "%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                                bytes[0], bytes[1], bytes[2], bytes[3],
                                bytes[4], bytes[5], bytes[6], bytes[7],
                                bytes[8], bytes[9], bytes[10], bytes[11],
                                bytes[12], bytes[13], bytes[14], bytes[15],
                                bytes[16], bytes[17], bytes[18], bytes[19],
                                bytes[20], bytes[21], bytes[22], bytes[23])
        }
        
        var attriString = AttributedString(string)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = LazyHexLine.lineHeight
        var container = AttributeContainer()
        container.paragraphStyle = paragraphStyle
        container.backgroundColor = (isEvenLine ? Color(red: 244.0/255, green: 245.0/255, blue: 245.0/255) : .white)
        
        attriString.setAttributes(container)
        
        for index in 1..<(HexadecimalStore.NumberOfBytesPerLine / 4) {
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

class HexadecimalStore: Equatable {
    
    static let NumberOfBytesPerLine = 24
    
    static func == (lhs: HexadecimalStore, rhs: HexadecimalStore) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    private let dataSlice: DataSlice
    private let hexDigits: Int
    
    private(set) var binaryLines: [LazyHexLine]
    private var selectedBytesRange: Range<Int>?
    
    init(_ component: MachoComponent, hexDigits: Int) {
        let dataSlice = component.dataSlice
        self.dataSlice = dataSlice
        self.hexDigits = hexDigits
        
        if component is MachoZeroFilledComponent {
            self.binaryLines = []
        } else {
            var numberOfBinaryLines = dataSlice.count / HexadecimalStore.NumberOfBytesPerLine
            if dataSlice.count % HexadecimalStore.NumberOfBytesPerLine != 0  { numberOfBinaryLines += 1 }
            
            var binaryLines: [LazyHexLine] = []
            for index in 0..<numberOfBinaryLines {
                binaryLines.append(LazyHexLine(offset: index * HexadecimalStore.NumberOfBytesPerLine,
                                               baseOffset: dataSlice.startOffset,
                                               indexNumOfDigits: hexDigits,
                                               isEvenLine: index & 0x1 == 0))
            }
            self.binaryLines = binaryLines
        }
        self.binaryLines.forEach { $0.store = self }
    }
    
    fileprivate func bytes(at offset: Int, length: Int) -> [UInt8] {
        return [UInt8](dataSlice.truncated(from: offset, maxLength: length).raw)
    }
    
    func targetLineIndexRange(for highLightedDataRange: Range<Int>) -> ClosedRange<Int> {
        let startDifference = max(0, highLightedDataRange.lowerBound - dataSlice.startOffset)
        let endDifference = max(0, highLightedDataRange.upperBound - dataSlice.startOffset)
        let startIndex = startDifference / HexadecimalStore.NumberOfBytesPerLine
        var endIndex = endDifference / HexadecimalStore.NumberOfBytesPerLine
        if endDifference != 0 && endDifference % HexadecimalStore.NumberOfBytesPerLine == 0 { endIndex -= 1 }
        return startIndex...endIndex
    }
    
    func updateLinesWith(selectedBytesRange: Range<Int>?) {
        if let previoutsSelectedBytesRange = self.selectedBytesRange {
            for index in targetLineIndexRange(for: previoutsSelectedBytesRange) {
                binaryLines[index].selectedByteRange = nil
            }
        }
        
        if let selectedBytesRange = selectedBytesRange {
            for index in targetLineIndexRange(for: selectedBytesRange) {
                let startDifference = max(0, (selectedBytesRange.lowerBound - binaryLines[index].fileOffset) * 2)
                var endDifference = max(0, (selectedBytesRange.upperBound - binaryLines[index].fileOffset) * 2)
                endDifference = min(HexadecimalStore.NumberOfBytesPerLine * 2, endDifference)
                
                let targetRangeLower = startDifference % (HexadecimalStore.NumberOfBytesPerLine * 2)
                var targetRangeHigher = endDifference % (HexadecimalStore.NumberOfBytesPerLine * 2)
                if targetRangeHigher == 0 { targetRangeHigher = HexadecimalStore.NumberOfBytesPerLine * 2 }
                
                binaryLines[index].selectedByteRange = targetRangeLower..<targetRangeHigher
            }
        }
        
        self.selectedBytesRange = selectedBytesRange
    }
}
