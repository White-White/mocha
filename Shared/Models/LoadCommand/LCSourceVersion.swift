//
//  LCSourceVersion.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCSourceVersion: LoadCommand {
    
    let version: String
    
    required init(with type: LoadCommandType, data: Data, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(data: data).skip(.quadWords)
        
        self.version = translationStore.translate(next: .quadWords,
                                                dataInterpreter: { LCSourceVersion.versionString(from: $0.UInt64) },
                                                itemContentGenerator: { version in TranslationItemContent(description: "Source Version", explanation: version) })
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
    
    static func versionString(from versionValue: UInt64) -> String {
        /* A.B.C.D.E packed as a24.b10.c10.d10.e10 */
        let mask: Swift.UInt64 = 0x3ff
        let e = versionValue & mask
        let d = (versionValue >> 10) & mask
        let c = (versionValue >> 20) & mask
        let b = (versionValue >> 30) & mask
        let a = versionValue >> 40
        return String(format: "%d.%d.%d.%d.%d", a, b, c, d, e)
    }
}
