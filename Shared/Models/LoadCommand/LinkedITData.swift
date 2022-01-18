//
//  LCLinkedIt.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

/* LC_CODE_SIGNATURE, LC_SEGMENT_SPLIT_INFO,
 LC_FUNCTION_STARTS, LC_DATA_IN_CODE,
 LC_DYLIB_CODE_SIGN_DRS,
 LC_LINKER_OPTIMIZATION_HINT,
 LC_DYLD_EXPORTS_TRIE, or
 LC_DYLD_CHAINED_FIXUPS. */

class LinkedITData: LoadCommand {
    
    let fileOffset: UInt32
    let dataSize: UInt32
    
    var interpreterType: Interpreter.Type {
        switch self.type {
        case .dataInCode:
            return LazyModelBasedInterpreter<DataInCodeModel>.self
        case .codeSignature:
            return CodeSignatureInterpreter.self
        case .functionStarts:
            return ULEB128Interpreter.self
        default:
            fatalError()
        }
    }
    
    var dataName: String {
        switch self.type {
        case .dataInCode:
            return "Data in Code"
        case .codeSignature:
            return "Code Signature"
        case .functionStarts:
            return "Function Starts"
        default:
            fatalError()
        }
    }
    
    required init(with type: LoadCommandType, data: DataSlice, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        self.fileOffset =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { fileOffset in TranslationItemContent(description: "File Offset", explanation: "\(fileOffset)") })
        
        self.dataSize =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { dataSize in TranslationItemContent(description: "Size", explanation: "\(dataSize)") })
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
}
