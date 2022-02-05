//
//  ACSIIInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/4.
//

import Foundation

class ASCIIInterpreter: BaseInterpreter<[String]> {
    
    private let numberOfASCIILines: Int
    
    override init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource) {
        var numberOfASCIILines = data.count / HexLineStore.NumberOfBytesPerLine
        if data.count % HexLineStore.NumberOfBytesPerLine != 0 { numberOfASCIILines += 1 }
        self.numberOfASCIILines = numberOfASCIILines
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }
    
    override var numberOfTranslationItems: Int {
        return numberOfASCIILines
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let lineData = self.data.truncated(from: index * HexLineStore.NumberOfBytesPerLine, maxLength: HexLineStore.NumberOfBytesPerLine)
        let chars = lineData.raw.map { char -> Character in
            if char < 32 || char > 126 {
                return "."
            }
            return Character(UnicodeScalar(char))
        }
        let string = String(chars)
        return TranslationItem(sourceDataRange: data.absoluteRange(index * HexLineStore.NumberOfBytesPerLine, HexLineStore.NumberOfBytesPerLine),
                               content: TranslationItemContent(description: nil, explanation: string, monoSpaced: true))
    }
}
