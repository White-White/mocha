//
//  Dylib.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LCDylib: LoadCommand {
    
    let libPathOffset: UInt32
    let libPath: String
    let timestamp: UInt32 /* library's build time stamp */
    var timestampString: String { Date(timeIntervalSince1970: TimeInterval(self.timestamp)).formatted() }
    let currentVersion: String /* library's current version number */
    let compatibilityVersion: String /* library's compatibility vers number*/
    
    required init(with type: LoadCommandType, data: DataSlice, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(machoDataSlice: data).skip(.quadWords)
        
        let libPathOffset =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { number in TranslationItemContent(description: "Path Offset", explanation: "\(number)") })
        self.libPathOffset = libPathOffset
        
        self.timestamp =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { number in TranslationItemContent(description: "Build Time", explanation: "\(number)") })
        
        self.currentVersion =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: { LCDylib.version(for: $0.UInt32) },
                                 itemContentGenerator: { version in TranslationItemContent(description: "Version", explanation: version) })
        
        self.compatibilityVersion =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: { LCDylib.version(for: $0.UInt32) },
                                 itemContentGenerator: { version in TranslationItemContent(description: "Comtatible Version", explanation: version) })
        
        self.libPath =
        translationStore.translate(next: .rawNumber(data.count - Int(libPathOffset)),
                                 dataInterpreter: { $0.utf8String?.spaceRemoved ?? Log.warning("Failed to parse dylib path. Debug me.") },
                                 itemContentGenerator: { path in TranslationItemContent(description: "Path", explanation: path) })
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
    
    static func version(for value: UInt32) -> String {
        return String(format: "%d.%d.%d", value >> 16, (value >> 8) & 0xff, value & 0xff)
    }
}
