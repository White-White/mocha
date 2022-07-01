//
//  HexadecimalLineViewModel.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/30.
//

import SwiftUI

struct HexadecimalLine {
    
    static let LineBytesCount = 24
    
    let dataSlice: DataSlice
    
    var offsetInMacho: Int {
        dataSlice.startOffset
    }
    
    var hexadecimalString: String {
        let bytes = [UInt8](dataSlice.raw)
        var hexadecimalStringData = [UInt8].init(repeating: 0x20, count: HexadecimalViewModel.LineBytesCount * 2)
        let hexArray: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46] // 0-9, A-F
        for (index, byte) in bytes.enumerated() {
            let upper4 = (byte & 0xF0) >> 4
            hexadecimalStringData[index * 2] = hexArray[Int(upper4)]
            let lower4 = byte & 0x0F
            hexadecimalStringData[index * 2 + 1] = hexArray[Int(lower4)]
        }
        return String(hexadecimalStringData.map { Character(UnicodeScalar($0)) })
    }

}

class HexadecimalLineViewModel: ObservableObject {
    
    let isEvenLine: Bool
    let hexDigits: Int
    
    @Published var highlightedDataRange: Range<Int>? = nil
    let line: HexadecimalLine
    
    var offsetInMachoString: String {
        String(format: "0x%0\(hexDigits)X", line.offsetInMacho)
    }
    
    var attributedHexadecimalString: AttributedString {
        var attriString = AttributedString(line.hexadecimalString)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 14
        var container = AttributeContainer()
        container.paragraphStyle = paragraphStyle
        container.backgroundColor = (isEvenLine ? Color(red: 244.0/255, green: 245.0/255, blue: 245.0/255) : .white)
        container.font = .system(size: 14).monospaced()
        attriString.setAttributes(container)
        
        for index in 1..<(HexadecimalLine.LineBytesCount / 4) {
            if let lowerBound = attriString.characters.index(attriString.startIndex, offsetBy: index * 8 - 1, limitedBy: attriString.endIndex),
               let upperBound = attriString.characters.index(attriString.startIndex, offsetBy: index * 8, limitedBy: attriString.endIndex) {
                if upperBound != attriString.endIndex {
                    attriString[lowerBound..<upperBound].kern = 4
                }
            }
        }
        
        if let highlightedDataRange = highlightedDataRange {
            if let lowerBound = attriString.characters.index(attriString.startIndex, offsetBy: highlightedDataRange.lowerBound * 2, limitedBy: attriString.endIndex),
               let upperBound = attriString.characters.index(attriString.startIndex, offsetBy: highlightedDataRange.upperBound * 2, limitedBy: attriString.endIndex) {
                attriString[lowerBound..<upperBound].backgroundColor = Theme.selected
                attriString[lowerBound..<upperBound].foregroundColor = .white
            }
        }
        
        return attriString
    }
    
    init(_ line: HexadecimalLine, isEvenLine: Bool, hexDigits: Int) {
        self.line = line
        self.isEvenLine = isEvenLine
        self.hexDigits = hexDigits
    }
    
    static func viewModels(from lines: [HexadecimalLine], hexDigits: Int) -> [HexadecimalLineViewModel] {
        var lineViewModels: [HexadecimalLineViewModel] = []
        for (index, line) in lines.enumerated() {
            lineViewModels.append(HexadecimalLineViewModel(line, isEvenLine: index % 2 != 0, hexDigits: hexDigits))
        }
        return lineViewModels
    }
    
}
