//
//  LinkerOption.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LCLinkerOption: LoadCommand {
    
    let numberOfOptions: UInt32
    let optionDataLength: Int
    let options: [String]
    
    init(with type: LoadCommandType, data: Data) {
        self.numberOfOptions = data.subSequence(from: 8, count: 4).UInt32
        self.optionDataLength = data.count - 12
        self.options = LCLinkerOption.options(from: data.subSequence(from: 12))
        super.init(data, type: type)
    }
    
    override var commandTranslations: [GeneralTranslation] {
        return [
            GeneralTranslation(definition: "Number of options", humanReadable: "\(self.numberOfOptions)", bytesCount: 4, translationType: .uint32),
            GeneralTranslation(definition: "Options(s)", humanReadable: self.options.joined(separator: " "), bytesCount: self.optionDataLength, translationType: .utf8String)
        ]
    }
    
    static func options(from data: Data) -> [String] {
        return data.split(separator: 0x00).map {
            if let optionString = String(data: $0, encoding: .utf8) {
                return optionString
            } else {
                return Log.warning("Unexpected, found unknown linker option. Breakpoint to debug")
            }
        }
    }
}
