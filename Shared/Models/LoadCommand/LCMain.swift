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
    
    required init(with type: LoadCommandType, data: DataSlice, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(machoDataSlice: data).skip(.quadWords)
        
        self.entryOffset = translationStore.translate(next: .quadWords,
                                                    dataInterpreter: { $0.UInt64 },
                                                    itemContentGenerator: { entryOffset in TranslationItemContent(description: "Entry Offset (relative to __TEXT)",
                                                                                                                  explanation: entryOffset.hex) })
        
        self.stackSize = translationStore.translate(next: .quadWords,
                                                  dataInterpreter: { $0.UInt64 },
                                                  itemContentGenerator: { stackSize in TranslationItemContent(description: "Stack Size",
                                                                                                              explanation: stackSize.hex) })
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
}
