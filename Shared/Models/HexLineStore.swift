//
//  BinaryStore.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation
import SwiftUI

protocol LazyHexLineBytesProvider: AnyObject {
    func bytes(at offset: Int, length: Int) -> [UInt8]
}

class LazyHexLine: ObservableObject {
    
    static let lineHeight: CGFloat = 14
    
    lazy var bytes: [UInt8] = {
        self.bytesProvider.bytes(at: self.offset, length: HexLineStore.NumberOfBytesPerLine)
    }()
    
    let bytesProvider: LazyHexLineBytesProvider
    let offset: Int
    let fileOffset: Int
    let indexNumOfDigits: Int
    let isEvenLine: Bool
    @Published var selectedByteRange: Range<Int>?
    
    init(offset: Int, baseOffset: Int, indexNumOfDigits: Int, isEvenLine: Bool, bytesProvider: LazyHexLineBytesProvider) {
        self.bytesProvider = bytesProvider
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
        if bytes.count < HexLineStore.NumberOfBytesPerLine {
            var tmpString = (bytes.map { String(format: "%02X", $0) }).joined(separator: "")
            let paddingLength = (HexLineStore.NumberOfBytesPerLine - bytes.count) * 2
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

class HexLineStore: Equatable, LazyHexLineBytesProvider {
    
    static func == (lhs: HexLineStore, rhs: HexLineStore) -> Bool {
        return lhs.data == rhs.data
    }
    
    static let NumberOfBytesPerLine = 24
    
    private let data: DataSlice
    private let hexDigits: Int
    
    var binaryLines: [LazyHexLine] = []
    private var selectedBytesRange: Range<Int>?
    
    init(_ data: DataSlice) {
        self.data = data
        self.hexDigits = data.preferredNumberOfHexDigits
        
        var numberOfBinaryLines = data.count / HexLineStore.NumberOfBytesPerLine
        if data.count % HexLineStore.NumberOfBytesPerLine != 0  { numberOfBinaryLines += 1 }
        
        var binaryLines: [LazyHexLine] = []
        for index in 0..<numberOfBinaryLines {
            binaryLines.append(LazyHexLine(offset: index * HexLineStore.NumberOfBytesPerLine,
                                           baseOffset: data.startIndex,
                                           indexNumOfDigits: hexDigits,
                                           isEvenLine: index & 0x1 == 0,
                                           bytesProvider: self))
        }
        
        self.binaryLines = binaryLines
    }
    
    func bytes(at offset: Int, length: Int) -> [UInt8] {
        return [UInt8](data.truncated(from: offset, maxLength: length).raw)
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
