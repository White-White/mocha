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
    
    required init(with type: LoadCommandType, data: DataSlice, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(machoDataSlice: data).skip(.quadWords)
        
        self.osVersion = translationStore.translate(next: .doubleWords,
                                                  dataInterpreter: { LCMinOSVersion.version(for: $0.UInt32) },
                                                  itemContentGenerator: { version in TranslationItemContent(description: "Required \(LCMinOSVersion.osName(for: type)) version", explanation: version) })
        
        self.sdkVersion = translationStore.translate(next: .doubleWords,
                                                   dataInterpreter: { LCMinOSVersion.version(for: $0.UInt32) },
                                                   itemContentGenerator: { version in TranslationItemContent(description: "Required min \(LCMinOSVersion.osName(for: type)) SDK version", explanation: version) })
        
        super.init(with: type, data: data, translationStore: translationStore)
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
