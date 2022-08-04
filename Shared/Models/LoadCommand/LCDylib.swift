//
//  Dylib.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LCDylib: LoadCommand {
    
    let libPathOffset: UInt32
    let libPathDataCount: Int
    let libPath: String
    let timestamp: UInt32 /* library's build time stamp */
    var timestampString: String { Date(timeIntervalSince1970: TimeInterval(self.timestamp)).formatted() }
    let currentVersion: String /* library's current version number */
    let compatibilityVersion: String /* library's compatibility vers number*/
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.libPathOffset = dataShifter.shiftUInt32()
        self.timestamp = dataShifter.shiftUInt32()
        self.currentVersion = LCDylib.version(for: dataShifter.shiftUInt32())
        self.compatibilityVersion = LCDylib.version(for: dataShifter.shiftUInt32())
        self.libPathDataCount = data.count - Int(self.libPathOffset)
        self.libPath = dataShifter.shift(.rawNumber(self.libPathDataCount)).utf8String?.spaceRemoved ?? Log.warning("Failed to parse dylib path. Debug me.")
        super.init(data, type: type, title: type.name, subTitle: libPath.components(separatedBy: "/").last)
    }
    
    override var commandTranslations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(definition: "Path Offset", humanReadable: "\(self.libPathOffset)", bytesCount: 4, translationType: .uint32))
        translations.append(Translation(definition: "Build Time", humanReadable: "\(self.timestamp)", bytesCount: 4, translationType: .uint32))
        translations.append(Translation(definition: "Version", humanReadable: self.currentVersion, bytesCount: 4, translationType: .versionString))
        translations.append(Translation(definition: "Compatible Version", humanReadable: self.compatibilityVersion, bytesCount: 4, translationType: .versionString))
        translations.append(Translation(definition: "Path", humanReadable: self.libPath, bytesCount: self.libPathDataCount, translationType: .utf8String))
        return translations
    }
    
    static func version(for value: UInt32) -> String {
        return String(format: "%d.%d.%d", value >> 16, (value >> 8) & 0xff, value & 0xff)
    }
}
