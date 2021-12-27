//
//  Section.swift
//  mocha
//
//  Created by white on 2021/6/24.
//

import Foundation

//enum SegmentType: String {
//    case __TEXT
//    case __DATA
//    case __LD
//    case __DWARF
//}
//
//enum SectionType: String {
//    case __text
//    case __cfstring
//    case __cstring
//    case __gcc_except_tab
//    case __literal8
//    case __objc_data
//    case __objc_superrefs
//    case __objc_methname
//    case __objc_selrefs
//    case __objc_classrefs
//    case __objc_classname
//    case __objc_const
//    case __objc_methtype
//    case __objc_ivar
//    case __data
//    case __objc_protorefs
//    case __const
//    case __bss
//    case __objc_classlist
//    case __objc_imageinfo
//    case __debug_abbrev
//    case __debug_info
//    case __debug_ranges
//    case __debug_str
//    case __apple_names
//    case __apple_objc
//    case __apple_namespac
//    case __apple_types
//    case __compact_unwind
//    case __eh_frame
//    case __debug_line
//}

struct SectionHeader {
    
    let segment: String
    let section: String
    let addr: UInt64
    let size: UInt64
    let offset: UInt32
    let align: UInt32
    let fileOffsetOfRelocationEntries: UInt32
    let numberOfRelocatioEntries: UInt32
    let flags: Data
    let reserved1: Data
    let reserved2: Data
    var reserved3: Data? // exists only for 64 bit
    
    let is64Bit: Bool
    let offsetInMacho: Int
    let data: SmartData
    var dataSize: Int { data.count }
    
    //    struct section { /* for 32-bit architectures */
    //        char        sectname[16];    /* name of this section */
    //        char        segname[16];    /* segment this section goes in */
    //        uint32_t    addr;        /* memory address of this section */
    //        uint32_t    size;        /* size in bytes of this section */
    //        uint32_t    offset;        /* file offset of this section */
    //        uint32_t    align;        /* section alignment (power of 2) */
    //        uint32_t    reloff;        /* file offset of relocation entries */
    //        uint32_t    nreloc;        /* number of relocation entries */
    //        uint32_t    flags;        /* flags (section type and attributes)*/
    //        uint32_t    reserved1;    /* reserved (for offset or index) */
    //        uint32_t    reserved2;    /* reserved (for count or sizeof) */
    //    };
    //
    //    struct section_64 { /* for 64-bit architectures */
    //        char        sectname[16];    /* name of this section */
    //        char        segname[16];    /* segment this section goes in */
    //        uint64_t    addr;        /* memory address of this section */
    //        uint64_t    size;        /* size in bytes of this section */
    //        uint32_t    offset;        /* file offset of this section */
    //        uint32_t    align;        /* section alignment (power of 2) */
    //        uint32_t    reloff;        /* file offset of relocation entries */
    //        uint32_t    nreloc;        /* number of relocation entries */
    //        uint32_t    flags;        /* flags (section type and attributes)*/
    //        uint32_t    reserved1;    /* reserved (for offset or index) */
    //        uint32_t    reserved2;    /* reserved (for count or sizeof) */
    //        uint32_t    reserved3;    /* reserved */
    //    };
    
    init(is64Bit: Bool, data: SmartData, offsetInMacho: Int) {
        self.is64Bit = is64Bit
        self.offsetInMacho = offsetInMacho
        self.data = data
        
        var dataShifter = DataShifter(data)
        
        guard let sectionName = dataShifter.shift(16).utf8String else { fatalError() /* Very unlikely */ }
        guard let segmentName = dataShifter.shift(16).utf8String else { fatalError() /* Very unlikely */ }
        self.segment = segmentName.spaceRemoved
        self.section = sectionName.spaceRemoved
        
        self.addr = (is64Bit ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.size = (is64Bit ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.offset = dataShifter.nextDoubleWord().UInt32
        self.align = dataShifter.nextDoubleWord().UInt32
        self.fileOffsetOfRelocationEntries = dataShifter.nextDoubleWord().UInt32
        self.numberOfRelocatioEntries = dataShifter.nextDoubleWord().UInt32
        self.flags = dataShifter.nextDoubleWord()
        self.reserved1 = dataShifter.nextDoubleWord()
        self.reserved2 = dataShifter.nextDoubleWord()
        self.reserved3 = is64Bit ? dataShifter.nextDoubleWord() : nil
    }
    
    func addTranslations(to store: inout BinaryTranslationStore) {
        store.translateNext(16) { Readable(description: "Section ame", explanation: self.section, dividerName: "Section Header") }
        store.translateNext(16) { Readable(description: "In segment", explanation: self.segment) }
        store.translateNext(is64Bit ? 8 : 4) { Readable(description: "Address in memory", explanation: self.addr.hex) } //FIXME: better explanation
        store.translateNext(is64Bit ? 8 : 4) { Readable(description: "size", explanation: self.size.hex) } //FIXME: better explanation
        store.translateNextDoubleWord { Readable(description: "offset", explanation: self.offset.hex) } //FIXME: better explanation
        store.translateNextDoubleWord { Readable(description: "align", explanation: "\(self.align)") } //FIXME: better explanation
        store.translateNextDoubleWord { Readable(description: "Reloc Entry Offset", explanation: self.fileOffsetOfRelocationEntries.hex) } //FIXME: better explanation
        store.translateNextDoubleWord { Readable(description: "Reloc Entry Num", explanation: "\(self.numberOfRelocatioEntries)") } //FIXME: better explanation
        store.translateNextDoubleWord { Readable(description: "Flags", explanation: nil) } //FIXME: better explanation
        store.translateNextDoubleWord { Readable(description: "reserved1", explanation: nil) } //FIXME: better explanation
        store.translateNextDoubleWord { Readable(description: "reserved2", explanation: nil) } //FIXME: better explanation
        if is64Bit { store.translateNextDoubleWord { Readable(description: "reserved3", explanation: nil) } } //FIXME: better explanation }
    }
}

class Section: Identifiable, Equatable, BinaryTranslationStoreGenerator {
    
    static func == (lhs: Section, rhs: Section) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    let header: SectionHeader
    let data: SmartData
    
    init(header: SectionHeader, data: SmartData) {
        self.header = header
        self.data = data
    }
    
    func binaryTranslationStore() -> BinaryTranslationStore {
        var store = BinaryTranslationStore(data: self.data, baseDataOffset: Int(header.offset))
        switch header.segment {
        case "__TEXT":
            switch header.section {
            case "__text":
                store.addTranslation(forRange: nil) { Readable(description: "Code", explanation: "This part of the macho file is your machine code. Hopper.app is a better tool for viewing it.") }
            case "__cstring", "__objc_methname", "__objc_classname", "__objc_methtype":
                var lastNullCharIndex: Int? // index of last null char ( "\0" )
                for (index, byte) in data.realData.enumerated() {
                    guard byte == 0 else { continue } // find null characters
                    let currentIndex = index
                    let lastIndex = lastNullCharIndex ?? -1
                    if currentIndex - lastIndex == 1 {
                        // skip continuous \0
                        lastNullCharIndex = currentIndex
                        continue
                    }
                    let dataStartIndex = lastIndex + 1 // lastIdnex points to last null, ignore
                    let dataLength = currentIndex - lastIndex - 1 // also ignore the last null
                    let stringData = data.select(from: dataStartIndex, length: dataLength)
                    store.addTranslation(forRange: dataStartIndex..<(dataStartIndex + dataLength)) {
                        if let string = String(data: stringData.realData, encoding: .utf8) {
                            return Readable(description: "UTF8 encoded string", explanation: string.replacingOccurrences(of: "\n", with: "\\n"))
                        } else {
                            return Readable(description: "Invalid utf8 encoded", explanation: "🙅‍♂️ Invalid utf8 string")
                        }
                    }
                    lastNullCharIndex = currentIndex
                }
            default:
                store.addTranslation(forRange: nil) { Readable(description: "Don's know how to parse this section.", explanation: "\(self.header.segment),\(self.header.section)") }
            }
        case "__DATA":
            fallthrough
        default:
            store.addTranslation(forRange: nil) { Readable(description: "Don's know how to parse this section.", explanation: "\(self.header.segment),\(self.header.section)") }
        }
        return store
    }
}
