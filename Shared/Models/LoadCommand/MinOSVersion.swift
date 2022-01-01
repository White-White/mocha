//
//  MinOSVersion.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class MinOSVersion: LoadCommand {
    
    private let osVersion: String
    private let sdkVersion: String
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        let osVersionConstraint = loadCommandData.truncated(from: 8, length: 4).raw.UInt32
        let sdkVersionConstraint = loadCommandData.truncated(from: 12, length: 4).raw.UInt32
        self.osVersion = String(format: "%d.%d.%d", osVersionConstraint >> 16, (osVersionConstraint >> 8) & 0xff, osVersionConstraint & 0xff)
        self.sdkVersion = String(format: "%d.%d.%d", sdkVersionConstraint >> 16, (sdkVersionConstraint >> 8) & 0xff, sdkVersionConstraint & 0xff)
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    var osName: String {
        switch self.loadCommandType {
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
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "\(self.osName), min required version:", explanation: "\(self.osVersion)") }
        section.translateNextDoubleWord { Readable(description: "min required sdk version:", explanation: "\(self.sdkVersion)") }
        return section
    }
}
