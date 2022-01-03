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
    let reserved1: Data
    let reserved2: Data
    var reserved3: Data? // exists only for 64 bit
    
    let is64Bit: Bool
    let data: DataSlice
    
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
        let flags = dataShifter.nextDoubleWord().UInt32
        
        let sectionTypeRawValue = flags & 0x000000ff
        guard let sectionType = SectionType(rawValue: sectionTypeRawValue) else {
            print("Unknown section type with raw value: \(sectionTypeRawValue). Contact the author.")
            fatalError()
        }
        self.sectionType = sectionType /* section type mask */
        self.sectionAttributes = flags & 0xffffff00 // section attributes mask
        self.reserved1 = dataShifter.nextDoubleWord()
        self.reserved2 = dataShifter.nextDoubleWord()
        self.reserved3 = is64Bit ? dataShifter.nextDoubleWord() : nil
    }
    
    func makeTranslationSection() -> TransSection {
        let section = TransSection(baseIndex: data.startIndex, title: "Section Header")
        section.translateNext(16) { Readable(description: "Section ame", explanation: self.section) }
        section.translateNext(16) { Readable(description: "In segment", explanation: self.segment) }
        section.translateNext(is64Bit ? 8 : 4) { Readable(description: "Address in memory", explanation: self.addr.hex) } //FIXME: better explanation
        section.translateNext(is64Bit ? 8 : 4) { Readable(description: "size", explanation: self.size.hex) } //FIXME: better explanation
        section.translateNextDoubleWord { Readable(description: "offset", explanation: self.offset.hex) } //FIXME: better explanation
        section.translateNextDoubleWord { Readable(description: "align", explanation: "\(self.align)") } //FIXME: better explanation
        section.translateNextDoubleWord { Readable(description: "Reloc Entry Offset", explanation: self.fileOffsetOfRelocationEntries.hex) } //FIXME: better explanation
        section.translateNextDoubleWord { Readable(description: "Reloc Entry Num", explanation: "\(self.numberOfRelocatioEntries)") } //FIXME: better explanation
        section.translateNextDoubleWord { Readable(description: "Section Type", explanation: "\(self.sectionType)") }
        section.translateNextDoubleWord { Readable(description: "reserved1", explanation: "//FIXME:") } //FIXME: better explanation
        section.translateNextDoubleWord { Readable(description: "reserved2", explanation: "//FIXME:") } //FIXME: better explanation
        if is64Bit { section.translateNextDoubleWord { Readable(description: "reserved3", explanation: "//FIXME:") } } //FIXME: better explanation }
        return section
    }
}
