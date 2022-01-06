//
//  ACSIIInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/4.
//

import Foundation

class ASCIIInterpreter: BaseInterpreter<[String]> {
    
    override func numberOfTransSections() -> Int {
        var numberOfASCIILines = data.count / HexLineStore.NumberOfBytesPerLine
        if data.count % HexLineStore.NumberOfBytesPerLine != 0 { numberOfASCIILines += 1 }
        return numberOfASCIILines
    }
    
    override func transSection(at index: Int) -> TransSection {
        let lineData = self.data.truncated(from: index * HexLineStore.NumberOfBytesPerLine, maxLength: HexLineStore.NumberOfBytesPerLine)
        let chars = lineData.raw.map { char -> Character in
            if char < 32 || char > 126 {
                return "."
            }
            return Character(UnicodeScalar(char))
        }
        let string = String(chars)
        let sectin = TransSection(baseIndex: self.data.startIndex + index * HexLineStore.NumberOfBytesPerLine, title: nil)
        sectin.translateNext(lineData.count) {
            Readable(description: nil, explanation: string, monoSpaced: true)
        }
        return sectin
    }
}
