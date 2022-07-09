//
//  LCOneString.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCMonoString: LoadCommand {
    
    let stringOffset: UInt32
    let string: String
    
    required init(with type: LoadCommandType, data: Data, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(data: data).skip(.quadWords)
        let stringOffset =  translationStore.translate(next: .doubleWords,
                                                     dataInterpreter: DataInterpreterPreset.UInt32,
                                                     itemContentGenerator: { stringOffset in TranslationItemContent(description: "String Offset", explanation: stringOffset.hex) })
        self.stringOffset = stringOffset
        
        self.string = translationStore.translate(next: .rawNumber(data.count - Int(stringOffset)),
                                               dataInterpreter: { $0.utf8String ?? Log.warning("Failed to parse \(type.name). Debug me.") },
                                               itemContentGenerator: { string in TranslationItemContent(description: "Content", explanation: string) })
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
}
