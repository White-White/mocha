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

class LCLinkedITData: LoadCommand {
    
    let containedDataFileOffset: UInt32
    let containedDataSize: UInt32
    
    var dataName: String {
        switch self.type {
        case .dataInCode:
            return "Data in Code"
        case .codeSignature:
            return "Code Signature"
        case .functionStarts:
            return "Function Starts"
        case .segmentSplitInfo:
            return "Segment Split Info"
        case .dylibCodeSigDRs:
            return "Dylib Code SigDRs"
        case .linkerOptimizationHint:
            return "Linker Opt Hint"
        case .dyldExportsTrie:
            return "Export Info (LC)"
        case .dyldChainedFixups:
            return "Dyld Chained Fixups"
        default:
            fatalError()
        }
    }
    
    required init(with type: LoadCommandType, data: Data, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(data: data).skip(.quadWords)
        
        self.containedDataFileOffset =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: DataInterpreterPreset.UInt32,
                                   itemContentGenerator: { fileOffset in TranslationItemContent(description: "File Offset", explanation: fileOffset.hex) })
        
        self.containedDataSize =
        translationStore.translate(next: .doubleWords,
                                   dataInterpreter: DataInterpreterPreset.UInt32,
                                   itemContentGenerator: { dataSize in TranslationItemContent(description: "Size", explanation: dataSize.hex) })
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
}
