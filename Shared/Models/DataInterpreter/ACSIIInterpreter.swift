//
//  ACSIIInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/4.
//

import Foundation

class ASCIIInterpreter: BaseInterpreter<[String]> {
    
    override func numberOfTranslationSections() -> Int {
        var numberOfASCIILines = data.count / HexLineStore.NumberOfBytesPerLine
        if data.count % HexLineStore.NumberOfBytesPerLine != 0 { numberOfASCIILines += 1 }
        return numberOfASCIILines
    }
    
    override func translationItems(at section: Int) -> [TranslationItem] {
        let lineData = self.data.truncated(from: section * HexLineStore.NumberOfBytesPerLine, maxLength: HexLineStore.NumberOfBytesPerLine)
        let chars = lineData.raw.map { char -> Character in
            if char < 32 || char > 126 {
                return "."
            }
            return Character(UnicodeScalar(char))
        }
        let string = String(chars)
        return [TranslationItem(sourceDataRange: data.absoluteRange(section * HexLineStore.NumberOfBytesPerLine, HexLineStore.NumberOfBytesPerLine),
                                content: TranslationItemContent(description: nil, explanation: string, monoSpaced: true))]
    }
}
