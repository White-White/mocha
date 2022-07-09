//
//  LCBuildVersion.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

enum BuildToolType: UInt32 {
    case clang = 1
    case swift
    case ld
    
    var readable: String {
        switch self {
        case .clang:
            return "Clang (TOOL_CLANG)"
        case .swift:
            return "Swift (TOOL_SWIFT)"
        case .ld:
            return "LD (TOOL_LD)"
        }
    }
}

enum BuildPlatform: UInt32 {
    case macOS = 1
    case iOS
    case tvOS
    case watchOS
    case bridgeOS
    case macCatalyst
    case iOSSimulator
    case tvOSSimulator
    case watchOSSimulator
    case driverKit
    
    var readable: String {
        switch self {
        case .macOS:
            return "PLATFORM_MACOS"
        case .iOS:
            return "PLATFORM_IOS"
        case .tvOS:
            return "PLATFORM_TVOS"
        case .watchOS:
            return "PLATFORM_WATCHOS"
        case .bridgeOS:
            return "PLATFORM_BRIDGEOS"
        case .macCatalyst:
            return "PLATFORM_MACCATALYST"
        case .iOSSimulator:
            return "PLATFORM_IOSSIMULATOR"
        case .tvOSSimulator:
            return "PLATFORM_TVOSSIMULATOR"
        case .watchOSSimulator:
            return "PLATFORM_WATCHOSSIMULATOR"
        case .driverKit:
            return "PLATFORM_DRIVERKIT"
        }
    }
}

struct LCBuildTool {
    let toolType: BuildToolType
    let version: String
}

class LCBuildVersion: LoadCommand {
    
    let platform: BuildPlatform?
    let minOSVersion: String
    let sdkVersion: String
    let numberOfTools: UInt32
    let buildTools: [LCBuildTool]
    
    required init(with type: LoadCommandType, data: Data, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(data: data).skip(.quadWords)
        
        self.platform =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: { data in BuildPlatform(rawValue: data.UInt32) },
                                   itemContentGenerator: { platform in
            TranslationItemContent(description: "Target Platform", explanation: platform?.readable ?? "⚠️ Unknown Platform. Contact the author.")
        })
        
        self.minOSVersion =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: { LCBuildVersion.version(for: $0.UInt32) },
                                   itemContentGenerator: { version in
            TranslationItemContent(description: "Min OS Version", explanation: version)
        })
        
        self.sdkVersion =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: { LCBuildVersion.version(for: $0.UInt32) },
                                   itemContentGenerator: { version in
            TranslationItemContent(description: "Min SDK Version", explanation: version)
        })
        
        let numberOfTools =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: DataInterpreterPreset.UInt32,
                                   itemContentGenerator: { value in
            TranslationItemContent(description: "Number of tool entries", explanation: "\(value)")
        })
        self.numberOfTools = numberOfTools
        
        var tools: [LCBuildTool] = []
        for _ in 0..<numberOfTools {
            let toolType =
            translationStore.translate(next: .doubleWords,
                                       dataInterpreter: { BuildToolType(rawValue: $0.UInt32)! },
                                       itemContentGenerator: { tool in
                TranslationItemContent(description: "Build Tool", explanation: tool.readable)
            })
            let toolVersion =
            translationStore.translate(next: .doubleWords,
                                       dataInterpreter: { LCBuildVersion.version(for: $0.UInt32) },
                                       itemContentGenerator: { toolVersion in
                TranslationItemContent(description: "Tool Version", explanation: toolVersion)
            })
            tools.append(LCBuildTool(toolType: toolType, version: toolVersion))
        }
        self.buildTools = tools
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
    
    static func version(for value: UInt32) -> String {
        return String(format: "%d.%d.%d", value >> 16, (value >> 8) & 0xff, value & 0xff)
    }
}
