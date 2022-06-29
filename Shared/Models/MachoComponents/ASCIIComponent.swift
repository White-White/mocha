//
//  ASCIIComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/4.
//

import Foundation

class ASCIIComponent: MachoLazyComponent<[String]> {
    
    private let numberOfASCIILines: Int
    
    override init(_ dataSlice: DataSlice, macho: Macho, is64Bit: Bool, title: String, subTitle: String?) {
        var numberOfASCIILines = dataSlice.count / HexadecimalStore.NumberOfBytesPerLine
        if dataSlice.count % HexadecimalStore.NumberOfBytesPerLine != 0 { numberOfASCIILines += 1 }
        self.numberOfASCIILines = numberOfASCIILines
        super.init(dataSlice, macho: macho, is64Bit: is64Bit, title: title, subTitle: subTitle)
    }
    
    override func numberOfTranslationSections() -> Int {
        return numberOfASCIILines
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let index = indexPath.section
        let lineData = dataSlice.truncated(from: index * HexadecimalStore.NumberOfBytesPerLine, maxLength: HexadecimalStore.NumberOfBytesPerLine)
        let chars = lineData.raw.map { char -> Character in
            if char < 32 || char > 126 {
                return "."
            }
            return Character(UnicodeScalar(char))
        }
        let string = String(chars)
        return TranslationItem(sourceDataRange: dataSlice.absoluteRange(index * HexadecimalStore.NumberOfBytesPerLine, HexadecimalStore.NumberOfBytesPerLine),
                               content: TranslationItemContent(description: nil, explanation: string, monoSpaced: true))
    }
}
