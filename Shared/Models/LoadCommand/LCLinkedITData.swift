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
    
    init(with type: LoadCommandType, data: Data) {
        self.containedDataFileOffset = data.subSequence(from: 8, count: 4).UInt32
        self.containedDataSize = data.subSequence(from: 12, count: 4).UInt32
        super.init(data, type: type)
    }
    
    override var commandTranslations: [GeneralTranslation] {
        return [
            GeneralTranslation(definition: "File Offset", humanReadable: self.containedDataFileOffset.hex, bytesCount: 4, translationType: .uint32),
            GeneralTranslation(definition: "Size", humanReadable: self.containedDataSize.hex, bytesCount: 4, translationType: .uint32)
        ]
    }
    
    func linkedITComponent(machoData:Data, machoHeader: MachoHeader, textSegmentLoadCommand: LCSegment?) -> MachoComponent {
        let is64Bit = machoHeader.is64Bit
        let data = machoData.subSequence(from: Int(self.containedDataFileOffset), count: Int(self.containedDataSize), allowZeroLength: true)
        switch self.type {
        case .dataInCode:
            return ModelBasedComponent<DataInCodeModel>(data, title: self.dataName, is64Bit: is64Bit)
        case .codeSignature:
            // ref: https://opensource.apple.com/source/Security/Security-55471/sec/Security/Tool/codesign.c
            // FIXME: better parsing
            return UnknownComponent(data, title: self.dataName)
        case .functionStarts:
            guard let textSegment = textSegmentLoadCommand else { fatalError() /* where there is function starts, there must be text segment */ }
            return FunctionStartsComponent(data, title: self.dataName, textSegmentVirtualAddress: textSegment.vmaddr)
        case .dyldExportsTrie:
            return ExportInfoComponent(data, title: self.dataName, is64Bit: is64Bit)
        default:
            print("Unknow how to parse \(self.type.name). Please contact the author.") // FIXME: LC_SEGMENT_SPLIT_INFO not parsed
            return UnknownComponent(data, title: title)
        }
    }
}
