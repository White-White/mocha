//
//  MinOSVersion.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LCMinOSVersion: LoadCommand {
    
    let osVersion: String
    let sdkVersion: String
    
    init(with type: LoadCommandType, data: Data) {
        self.osVersion = LCMinOSVersion.version(for: data.subSequence(from: 8, count: 4).UInt32)
        self.sdkVersion = LCMinOSVersion.version(for: data.subSequence(from: 12, count: 4).UInt32)
        super.init(data, type: type)
    }
    
    override var commandTranslations: [GeneralTranslation] {
        return [
            GeneralTranslation(definition: "Required min \(LCMinOSVersion.osName(for: type)) version", humanReadable: self.osVersion, bytesCount: 4, translationType: .versionString),
            GeneralTranslation(definition: "Required min \(LCMinOSVersion.osName(for: type)) SDK version", humanReadable: self.sdkVersion, bytesCount: 4, translationType: .versionString)
        ]
    }
    
    static func osName(for type: LoadCommandType) -> String {
        switch type {
        case .iOSMinVersion:
            return "iOS"
        case .macOSMinVersion:
            return "macOS"
        case .tvOSMinVersion:
            return "tvOS"
        case .watchOSMinVersion:
            return "watchOS"
        default:
            fatalError()
        }
    }
    
    static func version(for value: UInt32) -> String {
        return String(format: "%d.%d.%d", value >> 16, (value >> 8) & 0xff, value & 0xff)
    }
}
