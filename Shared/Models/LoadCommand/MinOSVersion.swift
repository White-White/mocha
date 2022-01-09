//
//  MinOSVersion.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class MinOSVersion: LoadCommand {
    
    let osVersion: String
    let sdkVersion: String
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        self.osVersion = itemsContainer.translate(next: .doubleWords,
                                                  dataInterpreter: { MinOSVersion.version(for: $0.UInt32) },
                                                  itemContentGenerator: { version in TranslationItemContent(description: "Required \(MinOSVersion.osName(for: type)) version", explanation: version) })
        
        self.sdkVersion = itemsContainer.translate(next: .doubleWords,
                                                   dataInterpreter: { MinOSVersion.version(for: $0.UInt32) },
                                                   itemContentGenerator: { version in TranslationItemContent(description: "Required min \(MinOSVersion.osName(for: type)) SDK version", explanation: version) })
        
        super.init(with: type, data: data, itemsContainer: itemsContainer)
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
