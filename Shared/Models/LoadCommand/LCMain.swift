//
//  LCMain.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCMain: LoadCommand {
    
    let entryOffset: UInt64
    let stackSize: UInt64
    
    init(with type: LoadCommandType, data: Data) {
        self.entryOffset = data.subSequence(from: 8, count: 8).UInt64
        self.stackSize = data.subSequence(from: 16, count: 8).UInt64
        super.init(data, type: type)
    }
    
    override var commandTranslations: [Translation] {
        return [Translation(definition: "Entry Offset (relative to __TEXT)", humanReadable: entryOffset.hex, bytesCount: 8, translationType: .uint64),
                Translation(definition: "Entry Offset (relative to __TEXT)", humanReadable: entryOffset.hex, bytesCount: 8, translationType: .uint64)]
    }
    
}
