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

struct SymbolTable: SmartDataContainer, TranslationStore {
    
    let smartData: SmartData
    let is64Bit: Bool
    let numberOfEntries: Int
    
    init(_ data: SmartData, numberOfEntries: Int, is64Bit: Bool) {
        self.smartData = data
        self.is64Bit = is64Bit
        self.numberOfEntries = numberOfEntries
    }
    
    var numberOfTranslationSections: Int { numberOfEntries }
    
    func translationSection(at index: Int) -> TranslationSection {
        if index >= numberOfEntries { fatalError() }
        let entrySize = is64Bit ? 16 : 12
        let dataStartIndex = index * entrySize
//        let data = data.truncated(from: dataStartIndex, length: entrySize).raw
        let section = TranslationSection(baseIndex: dataStartIndex, title: "Symbol Table Entry")
        section.translateNext(entrySize) { Readable(description: "Symbol", explanation: "//FIXME:") } //FIXME:
        return section
    }
}

class LCSymbolTable: LoadCommand {
    
//    struct symtab_command {
//        uint32_t    cmd;        /* LC_SYMTAB */
//        uint32_t    cmdsize;    /* sizeof(struct symtab_command) */
//        uint32_t    symoff;        /* symbol table offset */
//        uint32_t    nsyms;        /* number of symbol table entries */
//        uint32_t    stroff;        /* string table offset */
//        uint32_t    strsize;    /* string table size in bytes */
//    };
    
    let symbolTableOffset: UInt32
    let numberOfSymbolTableEntries: UInt32
    let stringTableOffset: UInt32
    let sizeOfStringTable: UInt32
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        var shifter = DataShifter(loadCommandData)
        _ = shifter.nextQuadWord() // skip basic data
        self.symbolTableOffset = shifter.nextDoubleWord().UInt32
        self.numberOfSymbolTableEntries = shifter.nextDoubleWord().UInt32
        self.stringTableOffset = shifter.nextDoubleWord().UInt32
        self.sizeOfStringTable = shifter.nextDoubleWord().UInt32
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TranslationSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "Symbol table offset", explanation: "\(self.symbolTableOffset.hex)") }
        section.translateNextDoubleWord { Readable(description: "Number of entries", explanation: "\(self.numberOfSymbolTableEntries)") }
        section.translateNextDoubleWord { Readable(description: "String table offset", explanation: "\(self.stringTableOffset.hex)") }
        section.translateNextDoubleWord { Readable(description: "Size of string table", explanation: self.sizeOfStringTable.hex) }
        return section
    }
}

struct DynamicSymbolTable {
    
}

class LCDynamicSymbolTable: LoadCommand {
    let ilocalsym: UInt32       /* index to local symbols */
    let nlocalsym: UInt32       /* number of local symbols */
    
    let iextdefsym: UInt32      /* index to externally defined symbols */
    let nextdefsym: UInt32      /* number of externally defined symbols */
    
    let iundefsym: UInt32       /* index to undefined symbols */
    let nundefsym: UInt32       /* number of undefined symbols */
    
    let tocoff: UInt32          /* file offset to table of contents */
    let ntoc: UInt32            /* number of entries in table of contents */
    
    let modtaboff: UInt32       /* file offset to module table */
    let nmodtab: UInt32         /* number of module table entries */
    
    let extrefsymoff: UInt32    /* offset to referenced symbol table */
    let nextrefsyms: UInt32     /* number of referenced symbol table entries */
    
    let indirectsymoff: UInt32  /* file offset to the indirect symbol table */
    let nindirectsyms: UInt32   /* number of indirect symbol table entries */
    
    let extreloff: UInt32       /* offset to external relocation entries */
    let nextrel: UInt32         /* number of external relocation entries */
    
    let locreloff: UInt32       /* offset to local relocation entries */
    let nlocrel: UInt32         /* number of local relocation entries */
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        var shifter = DataShifter(loadCommandData)
        _ = shifter.nextQuadWord() // skip basic data
        self.ilocalsym = shifter.nextDoubleWord().UInt32
        self.nlocalsym = shifter.nextDoubleWord().UInt32
        self.iextdefsym = shifter.nextDoubleWord().UInt32
        self.nextdefsym = shifter.nextDoubleWord().UInt32
        self.iundefsym = shifter.nextDoubleWord().UInt32
        self.nundefsym = shifter.nextDoubleWord().UInt32
        self.tocoff = shifter.nextDoubleWord().UInt32
        self.ntoc = shifter.nextDoubleWord().UInt32
        self.modtaboff = shifter.nextDoubleWord().UInt32
        self.nmodtab = shifter.nextDoubleWord().UInt32
        self.extrefsymoff = shifter.nextDoubleWord().UInt32
        self.nextrefsyms = shifter.nextDoubleWord().UInt32
        self.indirectsymoff = shifter.nextDoubleWord().UInt32
        self.nindirectsyms = shifter.nextDoubleWord().UInt32
        self.extreloff = shifter.nextDoubleWord().UInt32
        self.nextrel = shifter.nextDoubleWord().UInt32
        self.locreloff = shifter.nextDoubleWord().UInt32
        self.nlocrel = shifter.nextDoubleWord().UInt32
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TranslationSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "index to local symbols ", explanation: "\(self.ilocalsym)") }
        section.translateNextDoubleWord { Readable(description: "number of local symbols ", explanation: "\(self.nlocalsym)") }
        section.translateNextDoubleWord { Readable(description: "index to externally defined symbols ", explanation: "\(self.iextdefsym)") }
        section.translateNextDoubleWord { Readable(description: "number of externally defined symbols ", explanation: "\(self.nextdefsym)") }
        section.translateNextDoubleWord { Readable(description: "index to undefined symbols ", explanation: "\(self.iundefsym)") }
        section.translateNextDoubleWord { Readable(description: "number of undefined symbols ", explanation: "\(self.nundefsym)") }
        section.translateNextDoubleWord { Readable(description: "file offset to table of contents ", explanation: "\(self.tocoff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of entries in table of contents ", explanation: "\(self.ntoc)") }
        section.translateNextDoubleWord { Readable(description: "file offset to module table ", explanation: "\(self.modtaboff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of module table entries ", explanation: "\(self.nmodtab)") }
        section.translateNextDoubleWord { Readable(description: "offset to referenced symbol table ", explanation: "\(self.extrefsymoff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of referenced symbol table entries ", explanation: "\(self.nextrefsyms)") }
        section.translateNextDoubleWord { Readable(description: "file offset to the indirect symbol table ", explanation: "\(self.indirectsymoff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of indirect symbol table entries ", explanation: "\(self.nindirectsyms)") }
        section.translateNextDoubleWord { Readable(description: "offset to external relocation entries ", explanation: "\(self.extreloff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of external relocation entries ", explanation: "\(self.nextrel)") }
        section.translateNextDoubleWord { Readable(description: "offset to local relocation entries ", explanation: "\(self.locreloff.hex)") }
        section.translateNextDoubleWord { Readable(description: "number of local relocation entries ", explanation: "\(self.nlocrel)") }
        return section
    }
}
