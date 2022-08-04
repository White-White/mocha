//
//  LCOneString.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCMonoString: LoadCommand {
    
    let stringOffset: UInt32
    let stringLength: Int
    let string: String
    
    init(with type: LoadCommandType, data: Data) {
        self.stringOffset = data.subSequence(from: 8, count: 4).UInt32
        self.stringLength = data.count - Int(self.stringOffset)
        self.string = data.subSequence(from: Int(self.stringOffset)).utf8String ?? Log.warning("Failed to parse \(type.name). Debug me.")
        super.init(data, type: type)
    }
    
    override var commandTranslations: [Translation] {
        return [
            Translation(definition: "String Offset", humanReadable: self.stringOffset.hex, bytesCount: 4, translationType: .uint32),
            Translation(definition: "Content", humanReadable: string, bytesCount: self.stringLength, translationType: .utf8String)
        ]
    }
}
