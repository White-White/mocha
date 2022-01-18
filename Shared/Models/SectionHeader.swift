//
//  Section.swift
//  mocha
//
//  Created by white on 2021/6/24.
//

import Foundation

enum SectionType: UInt32 {
    case S_REGULAR = 0
    case S_ZEROFILL
    case S_CSTRING_LITERALS
    case S_4BYTE_LITERALS
    case S_8BYTE_LITERALS
    case S_LITERAL_POINTERS
    case S_NON_LAZY_SYMBOL_POINTERS
    case S_LAZY_SYMBOL_POINTERS
    case S_SYMBOL_STUBS
    case S_MOD_INIT_FUNC_POINTERS
    case S_MOD_TERM_FUNC_POINTERS
    case S_COALESCED
    case S_GB_ZEROFILL
    case S_INTERPOSING
    case S_16BYTE_LITERALS
    case S_DTRACE_DOF
    case S_LAZY_DYLIB_SYMBOL_POINTERS
    case S_THREAD_LOCAL_REGULAR
    case S_THREAD_LOCAL_ZEROFILL
    case S_THREAD_LOCAL_VARIABLES
    case S_THREAD_LOCAL_VARIABLE_POINTERS
    case S_THREAD_LOCAL_INIT_FUNCTION_POINTERS
    case S_INIT_FUNC_OFFSETS
}

struct SectionHeader {
    
    let segment: String
    let section: String
    let addr: UInt64
    let size: UInt64
    let offset: UInt32
    let align: UInt32
    let fileOffsetOfRelocationEntries: UInt32
    let numberOfRelocatioEntries: UInt32
    let sectionType: SectionType
    let sectionAttributes: UInt32
    let reserved1: UInt32
    let reserved2: UInt32
    let reserved3: UInt32? // exists only for 64 bit
    
    let is64Bit: Bool
    let data: DataSlice
    let translationStore: TranslationStore
    
    var isZerofilled: Bool {
        // ref: https://lists.llvm.org/pipermail/llvm-commits/Week-of-Mon-20151207/319108.html
        // code snipet from llvm
        
        /*
         inline bool isZeroFillSection(SectionType T) {
         return (T == llvm::MachO::S_ZEROFILL ||
         T == llvm::MachO::S_THREAD_LOCAL_ZEROFILL);
         }
         */
        
        return sectionType == .S_ZEROFILL || sectionType == .S_THREAD_LOCAL_ZEROFILL
    }
    
    init(is64Bit: Bool, data: DataSlice) {
        self.is64Bit = is64Bit
        self.data = data
        
        let translationStore = TranslationStore(machoDataSlice: data)
        
        self.section =
        translationStore.translate(next: .rawNumber(16),
                                 dataInterpreter: { $0.utf8String!.spaceRemoved /* Very unlikely crash */ },
                                 itemContentGenerator: { string in TranslationItemContent(description: "Section Name", explanation: string) })
        
        self.segment =
        translationStore.translate(next: .rawNumber(16),
                                 dataInterpreter: { $0.utf8String!.spaceRemoved /* Very unlikely crash */ },
                                 itemContentGenerator: { string in TranslationItemContent(description: "Segment Name", explanation: string) })
        
        self.addr =
        translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                 dataInterpreter: { $0.UInt64 },
                                 itemContentGenerator: { value in TranslationItemContent(description: "Address in memory", explanation: value.hex) })
        
        self.size =
        translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                 dataInterpreter: { $0.UInt64 },
                                 itemContentGenerator: { value in TranslationItemContent(description: "Size", explanation: value.hex) })
        
        self.offset =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "File Offset", explanation: value.hex) })
        
        self.align =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Align", explanation: "\(value)") })
        
        self.fileOffsetOfRelocationEntries =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Reloc Entry Offset", explanation: value.hex) })
        
        self.numberOfRelocatioEntries =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Reloc Entry Num", explanation: "\(value)") })
        
        // parse flags
        let flags = data.truncated(from: translationStore.translated, length: 4).raw.UInt32
        let rangeOfNextDWords = data.absoluteRange(translationStore.translated, 4)
        
        let sectionTypeRawValue = flags & 0x000000ff
        guard let sectionType = SectionType(rawValue: sectionTypeRawValue) else {
            print("Unknown section type with raw value: \(sectionTypeRawValue). Contact the author.")
            fatalError()
        }
        self.sectionType = sectionType
        translationStore.append(TranslationItemContent(description: "Section Type", explanation: "\(sectionType)"), forRange: rangeOfNextDWords)
        
        let sectionAttributes = flags & 0xffffff00 // section attributes mask
        translationStore.append(TranslationItemContent(description: "Section Type", explanation: "\(sectionAttributes.hex)"), forRange: rangeOfNextDWords)
        self.sectionAttributes = sectionAttributes
        
        _ = translationStore.skip(.doubleWords)
        
        self.reserved1 =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "reserved1", explanation: value.hex) })
        
        self.reserved2 =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "reserved2", explanation: value.hex) })
        
        if is64Bit {
            self.reserved3 =
            translationStore.translate(next: .doubleWords,
                                     dataInterpreter: DataInterpreterPreset.UInt32,
                                     itemContentGenerator: { value in TranslationItemContent(description: "reserved3", explanation: value.hex, hasDivider: true) })
        } else {
            self.reserved3 = nil
        }
        
        self.translationStore = translationStore
    }
    
    static func numberOfTranslationItems(is64Bit: Bool) -> Int {
        return is64Bit ? 13 : 12
    }
}
