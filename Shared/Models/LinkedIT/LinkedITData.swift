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

class LinkedITData: LoadCommand, TranslatorContainerGenerator {
    
    let fileOffset: UInt32
    let dataSize: UInt32
    let dataName: String
    let translatorType: Translator.Type
    
    init(with loadCommandData: SmartData, loadCommandType: LoadCommandType, dataName: String, translatorType: Translator.Type) {
        self.fileOffset = loadCommandData.truncated(from: 8, length: 4).raw.UInt32
        self.dataSize = loadCommandData.truncated(from: 12, length: 4).raw.UInt32
        self.dataName = dataName
        self.translatorType = translatorType
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "File Offset", explanation: "\(self.fileOffset.hex)") }
        section.translateNextDoubleWord { Readable(description: "Size", explanation: "\(self.dataSize)") }
        return section
    }
    
    func makeTranslatorContainers(from machoData: SmartData, is64Bit: Bool) -> [TranslatorContainer] {
        let data = machoData.truncated(from: Int(fileOffset), length: Int(dataSize))
        return [TranslatorContainer(data, is64Bit: is64Bit,
                                    translatorType: translatorType,
                                    primaryName: self.dataName,
                                    secondaryName: "__LINKEDIT")]
    }
}

class CodeSignatureTranslator: AnonymousTranslator {
    // ref: https://opensource.apple.com/source/Security/Security-55471/sec/Security/Tool/codesign.c
    // we treat parse code signature as a single arbitrary binary
    override var description: String { "Code Signature" }
    override var explanation: String { "We are not parsing this." }
}

