//
//  Dylib.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class Dylib: LoadCommand {
    
    let libPathOffset: UInt32
    let libPath: String
    let timestamp: UInt32 /* library's build time stamp */
    var timestampString: String { Date(timeIntervalSince1970: TimeInterval(self.timestamp)).formatted() }
    let currentVersion: String /* library's current version number */
    let compatibilityVersion: String /* library's compatibility vers number*/
    
    override init(with loadCommandData: DataSlice, loadCommandType: LoadCommandType) {
        var shifter = DataShifter(loadCommandData)
        _ = shifter.nextQuadWord() // skip basic data
        let libPathOffset = shifter.nextDoubleWord().UInt32
        self.libPathOffset = libPathOffset
        self.timestamp = shifter.nextDoubleWord().UInt32
        let currentVersionValue = shifter.nextDoubleWord().UInt32
        let compatibilityVersionValue = shifter.nextDoubleWord().UInt32
        self.currentVersion = String(format: "%d.%d.%d", currentVersionValue >> 16, (currentVersionValue >> 8) & 0xff, currentVersionValue & 0xff)
        self.compatibilityVersion = String(format: "%d.%d.%d", compatibilityVersionValue >> 16, (compatibilityVersionValue >> 8) & 0xff, compatibilityVersionValue & 0xff)
        if let libPath = loadCommandData.truncated(from: Int(libPathOffset)).raw.utf8String {
            self.libPath = libPath.spaceRemoved
        } else {
            self.libPath = Log.warning("Failed to parse dylib path. Debug me.")
        }
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "Path Offset", explanation: "\(self.libPathOffset)") }
        section.translateNextDoubleWord { Readable(description: "Build Time", explanation: self.timestampString) }
        section.translateNextDoubleWord { Readable(description: "Version", explanation: self.currentVersion) }
        section.translateNextDoubleWord { Readable(description: "Comtatible Version", explanation: self.compatibilityVersion) }
        section.translateNext(libPath.count) { Readable(description: "Path", explanation: self.libPath) }
        return section
    }
}
