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

enum SectionAttribute {
    case S_ATTR_PURE_INSTRUCTIONS
    case S_ATTR_NO_TOC
    case S_ATTR_STRIP_STATIC_SYMS
    case S_ATTR_NO_DEAD_STRIP
    case S_ATTR_LIVE_SUPPORT
    case S_ATTR_SELF_MODIFYING_CODE
    case S_ATTR_DEBUG
    case S_ATTR_SOME_INSTRUCTIONS
    case S_ATTR_EXT_RELOC
    case S_ATTR_LOC_RELOC
    
    var name: String {
        switch self {
        case .S_ATTR_PURE_INSTRUCTIONS:
            return "S_ATTR_PURE_INSTRUCTIONS"
        case .S_ATTR_NO_TOC:
            return "S_ATTR_NO_TOC"
        case .S_ATTR_STRIP_STATIC_SYMS:
            return "S_ATTR_STRIP_STATIC_SYMS"
        case .S_ATTR_NO_DEAD_STRIP:
            return "S_ATTR_NO_DEAD_STRIP"
        case .S_ATTR_LIVE_SUPPORT:
            return "S_ATTR_LIVE_SUPPORT"
        case .S_ATTR_SELF_MODIFYING_CODE:
            return "S_ATTR_SELF_MODIFYING_CODE"
        case .S_ATTR_DEBUG:
            return "S_ATTR_DEBUG"
        case .S_ATTR_SOME_INSTRUCTIONS:
            return "S_ATTR_SOME_INSTRUCTIONS"
        case .S_ATTR_EXT_RELOC:
            return "S_ATTR_EXT_RELOC"
        case .S_ATTR_LOC_RELOC:
            return "S_ATTR_LOC_RELOC"
        }
    }
}

struct SectionAttributes {
    
    let raw: UInt32
    let attributes: [SectionAttribute]
    
    var descriptions: [String] {
        if attributes.isEmpty {
            return ["NONE"]
        } else {
            return attributes.map({ $0.name })
        }
    }
    
    init(raw: UInt32) {
        self.raw = raw
        var attributes: [SectionAttribute] = []
        if raw.bitAnd(0x80000000) { attributes.append(.S_ATTR_PURE_INSTRUCTIONS) }
        if raw.bitAnd(0x40000000) { attributes.append(.S_ATTR_NO_TOC) }
        if raw.bitAnd(0x20000000) { attributes.append(.S_ATTR_STRIP_STATIC_SYMS) }
        if raw.bitAnd(0x10000000) { attributes.append(.S_ATTR_NO_DEAD_STRIP) }
        if raw.bitAnd(0x08000000) { attributes.append(.S_ATTR_LIVE_SUPPORT) }
        if raw.bitAnd(0x04000000) { attributes.append(.S_ATTR_SELF_MODIFYING_CODE) }
        if raw.bitAnd(0x02000000) { attributes.append(.S_ATTR_DEBUG) }
        if raw.bitAnd(0x00000400) { attributes.append(.S_ATTR_SOME_INSTRUCTIONS) }
        if raw.bitAnd(0x00000200) { attributes.append(.S_ATTR_EXT_RELOC) }
        if raw.bitAnd(0x00000100) { attributes.append(.S_ATTR_LOC_RELOC) }
        self.attributes = attributes
    }
    
    func hasAttribute(_ attri: SectionAttribute) -> Bool {
        return self.attributes.contains(attri)
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
    
    init(is64Bit: Bool, data: Data) {
        self.is64Bit = is64Bit
        var dataShifter = DataShifter(data)
        self.section = dataShifter.shift(.rawNumber(16)).utf8String!.spaceRemoved /* Very unlikely crash */
        self.segment = dataShifter.shift(.rawNumber(16)).utf8String!.spaceRemoved /* Very unlikely crash */
        self.addr = is64Bit ? dataShifter.shiftUInt64() : UInt64(dataShifter.shiftUInt32())
        self.size = is64Bit ? dataShifter.shiftUInt64() : UInt64(dataShifter.shiftUInt32())
        self.offset = dataShifter.shiftUInt32()
        self.align = dataShifter.shiftUInt32()
        self.fileOffsetOfRelocationEntries = dataShifter.shiftUInt32()
        self.numberOfRelocatioEntries = dataShifter.shiftUInt32()
        let flags = dataShifter.shiftUInt32()
        self.sectionType = SectionType(rawValue: flags & 0x000000ff)! /* unlikely to crash */
        self.sectionAttributes = SectionAttributes(raw: flags & 0xffffff00 /* section attributes mask */)
        self.reserved1 = dataShifter.shiftUInt32()
        self.reserved2 = dataShifter.shiftUInt32()
        self.reserved3 = is64Bit ? dataShifter.shiftUInt32() : nil
    }
    
    func getTranslations() -> [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(definition: "Section Name", humanReadable: self.section, bytesCount: 16, translationType: .utf8String))
        translations.append(Translation(definition: "Segment Name", humanReadable: self.segment, bytesCount: 16, translationType: .utf8String))
        translations.append(Translation(definition: "Virtual Address", humanReadable: self.addr.hex, bytesCount: self.is64Bit ? 8 : 4, translationType: .number))
        translations.append(Translation(definition: "Section Size", humanReadable: self.size.hex, bytesCount: self.is64Bit ? 8 : 4, translationType: .number))
        translations.append(Translation(definition: "File Offset", humanReadable: self.offset.hex, bytesCount: 4, translationType: .number))
        translations.append(Translation(definition: "Align", humanReadable: "\(self.align)", bytesCount: 4, translationType: .number))
        translations.append(Translation(definition: "Reloc Entry Offset", humanReadable: self.fileOffsetOfRelocationEntries.hex, bytesCount: 4, translationType: .number))
        translations.append(Translation(definition: "Reloc Entry Number", humanReadable: "\(self.numberOfRelocatioEntries)", bytesCount: 4, translationType: .number))
        translations.append(Translation(definition: "Section Type", humanReadable: "\(self.sectionType)", bytesCount: 1, translationType: .numberEnum))
        translations.append(Translation(definition: "Section Attributes", humanReadable: self.sectionAttributes.descriptions.joined(separator: "\n"), bytesCount: 3, translationType: .flags))
        translations.append(Translation(definition: self.sectionType.hasIndirectSymbolTableEntries ? "Indirect Symbol Table Index" : "reserved1", humanReadable: self.reserved1.hex, bytesCount: 4, translationType: .number))
        translations.append(Translation(definition: self.sectionType == .S_SYMBOL_STUBS ? "Stub Size" : "reserved2", humanReadable: self.reserved2.hex, bytesCount: 4, translationType: .number))
        if let reserved3 = self.reserved3 { translations.append(Translation(definition: "reserved3", humanReadable: reserved3.hex, bytesCount: 4, translationType: .number)) }
        return translations
    }
    
    func sectionComponent(machoData: Data, machoHeader: MachoHeader) -> MachoComponent {
        
        let is64Bit = machoHeader.is64Bit
        let title = self.segment + "," + self.section
        
        // recognize section by section type
        switch self.sectionType {
        case .S_ZEROFILL, .S_THREAD_LOCAL_ZEROFILL, .S_GB_ZEROFILL:
            // ref: https://lists.llvm.org/pipermail/llvm-commits/Week-of-Mon-20151207/319108.html
            /* code snipet from llvm
             inline bool isZeroFillSection(SectionType T) {
             return (T == llvm::MachO::S_ZEROFILL ||
             T == llvm::MachO::S_THREAD_LOCAL_ZEROFILL);
             }
             */
            return MachoZeroFilledComponent(runtimeSize: Int(self.size), title: title)
            
        case .S_CSTRING_LITERALS:
            let data = machoData.subSequence(from: Int(self.offset), count: Int(self.size))
            let cStringComponent = CStringSectionComponent(data, title: title, virtualAddress: self.addr)
            return cStringComponent
        case .S_LITERAL_POINTERS:
            let data = machoData.subSequence(from: Int(self.offset), count: Int(self.size))
            return LiteralPointerComponent(data, is64Bit: is64Bit, title: title)
        case .S_LAZY_SYMBOL_POINTERS, .S_NON_LAZY_SYMBOL_POINTERS, .S_LAZY_DYLIB_SYMBOL_POINTERS:
            let data = machoData.subSequence(from: Int(self.offset), count: Int(self.size))
            return SymbolPointerComponent(data, is64Bit: is64Bit, title: title, sectionHeader: self)
        default:
            break
        }
        
        // recognize section by section attributes
        if self.sectionAttributes.hasAttribute(.S_ATTR_PURE_INSTRUCTIONS) {
            let data = machoData.subSequence(from: Int(self.offset), count: Int(self.size))
            return InstructionComponent(data, title: title, cpuType: machoHeader.cpuType)
        }
        
        // recognize section by section name
        let data = machoData.subSequence(from: Int(self.offset), count: Int(self.size), allowZeroLength: true)
        switch self.segment {
        case Constants.sectionNameTEXT:
            switch self.section {
            case Constants.sectionNameUString:
                return UStringComponent(data, title: title)
            case "__swift5_reflstr":
                // https://knight.sc/reverse%20engineering/2019/07/17/swift-metadata.html
                // a great article on introducing swift metadata sections
                return CStringSectionComponent(data, title: title, virtualAddress: self.addr)
            default:
                return MachoUnknownCodeComponent(data, title: title)
            }
        default:
            return MachoUnknownCodeComponent(data, title: title)
        }
    }
    
}
