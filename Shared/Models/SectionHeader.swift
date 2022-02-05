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
    
    var hasIndirectSymbolTableEntries: Bool {
        switch self {
        case .S_NON_LAZY_SYMBOL_POINTERS, .S_LAZY_SYMBOL_POINTERS, .S_LAZY_DYLIB_SYMBOL_POINTERS, .S_SYMBOL_STUBS:
            return true
        default:
            return false
        }
    }
}

struct SectionAttributes {
    let descriptions: [String]
    init(raw: UInt32) {
        var descriptions: [String] = []
        if raw.bitAnd(0x80000000) { descriptions.append("S_ATTR_PURE_INSTRUCTIONS") }
        if raw.bitAnd(0x40000000) { descriptions.append("S_ATTR_NO_TOC") }
        if raw.bitAnd(0x20000000) { descriptions.append("S_ATTR_STRIP_STATIC_SYMS") }
        if raw.bitAnd(0x10000000) { descriptions.append("S_ATTR_NO_DEAD_STRIP") }
        if raw.bitAnd(0x08000000) { descriptions.append("S_ATTR_LIVE_SUPPORT") }
        if raw.bitAnd(0x04000000) { descriptions.append("S_ATTR_SELF_MODIFYING_CODE") }
        if raw.bitAnd(0x02000000) { descriptions.append("S_ATTR_DEBUG") }
        if raw.bitAnd(0x00000400) { descriptions.append("S_ATTR_SOME_INSTRUCTIONS") }
        if raw.bitAnd(0x00000200) { descriptions.append("S_ATTR_EXT_RELOC") }
        if raw.bitAnd(0x00000100) { descriptions.append("S_ATTR_LOC_RELOC") }
        if descriptions.isEmpty { descriptions.append("NONE") }
        self.descriptions = descriptions
    }
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
    let sectionAttributes: SectionAttributes
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
                                 itemContentGenerator: { value in TranslationItemContent(description: "Virtual Address", explanation: value.hex) })
        
        self.size =
        translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                 dataInterpreter: { $0.UInt64 },
                                 itemContentGenerator: { value in TranslationItemContent(description: "Section Size", explanation: value.hex) })
        
        self.offset =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "File Offset", explanation: value.hex) })
        
        self.align =
        translationStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Align", explanation: "\(value)") })
        
        let relocValues: (UInt32, UInt32) =
        translationStore.translate(next: .quadWords,
                                   dataInterpreter: { data in (data.select(from: 0, length: 4).UInt32, data.select(from: 4, length: 4).UInt32) },
                                   itemContentGenerator: { values in TranslationItemContent(description: "Reloc Entry Offset / Number", explanation: values.0.hex + " / \(values.1)") })
        self.fileOffsetOfRelocationEntries = relocValues.0
        self.numberOfRelocatioEntries = relocValues.1
        
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
        
        let sectionAttributesRaw = flags & 0xffffff00 // section attributes mask
        let sectionAttributes =  SectionAttributes(raw: sectionAttributesRaw)
        translationStore.append(TranslationItemContent(description: "Section Attributes", explanation: sectionAttributes.descriptions.joined(separator: "\n")), forRange: rangeOfNextDWords)
        self.sectionAttributes = sectionAttributes
        
        _ = translationStore.skip(.doubleWords)
        
        var reserved1Description = "reserved1"
        if sectionType.hasIndirectSymbolTableEntries { reserved1Description = "Indirect Symbol Table Index" }
        
        var reserved2Description = "reserved2"
        if sectionType == .S_SYMBOL_STUBS { reserved2Description = "Stub Size" }
        
        let reservedValue: (UInt32, UInt32, UInt32?) =
        translationStore.translate(next: .rawNumber(is64Bit ? 12 : 8),
                                   dataInterpreter: { data -> (UInt32, UInt32, UInt32?) in (data.select(from: 0, length: 4).UInt32,
                                                                                            data.select(from: 4, length: 4).UInt32,
                                                                                            is64Bit ? data.select(from: 8, length: 4).UInt32 : nil) },
                                   itemContentGenerator: { values in TranslationItemContent(description: "\(reserved1Description) / \(reserved2Description)" + (values.2 == nil ? "" : " / reserved3"),
                                                                                            explanation: "\(values.0) / \(values.1)" + (values.2 == nil ? "" : " / \(values.2!)"),
                                                                                            hasDivider: true) })
        
        self.reserved1 = reservedValue.0
        self.reserved2 = reservedValue.1
        self.reserved3 = reservedValue.2
        
        self.translationStore = translationStore
    }
    
    static func numberOfTranslationItems(is64Bit: Bool) -> Int {
        return 10
    }
}
