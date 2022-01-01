//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/15.
//

import Foundation

//struct nlist {
//    union {
//#ifndef __LP64__
//        char *n_name;    /* for use when in-core */
//#endif
//        uint32_t n_strx;    /* index into the string table */
//    } n_un;
//    uint8_t n_type;        /* type flag, see below */
//    uint8_t n_sect;        /* section number or NO_SECT */
//    int16_t n_desc;        /* see <mach-o/stab.h> */
//    uint32_t n_value;    /* value of this symbol (or stab offset) */
//};
//
///*
// * This is the symbol table entry structure for 64-bit architectures.
// */
//struct nlist_64 {
//    union {
//        uint32_t  n_strx; /* index into the string table */
//    } n_un;
//    uint8_t n_type;        /* type flag, see below */
//    uint8_t n_sect;        /* section number or NO_SECT */
//    uint16_t n_desc;       /* see <mach-o/stab.h> */
//    uint64_t n_value;      /* value of this symbol (or stab offset) */
//};

struct SymbolTableEntryModel: TranslatableModel {
    
    let data: SmartData
    let is64Bit: Bool
    
    init(with data: SmartData, is64Bit: Bool) {
        self.data = data
        self.is64Bit = is64Bit
    }
    
    func makeTransSection() -> TransSection {
        let entrySize = is64Bit ? 16 : 12
        let section = TransSection(baseIndex: data.startOffsetInMacho, title: "Symbol Table Entry")
        section.translateNext(entrySize) { Readable(description: "Symbol", explanation: "//FIXME:") } //FIXME:
        return section
    }
    
    static func modelName() -> String? {
        return "Symbol Table"
    }
    
    static func modelSize(is64Bit: Bool) -> Int {
        return is64Bit ? 16 : 12
    }
}

struct DynamicSymbolTable {
    
}
