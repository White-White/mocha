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

struct SymbolTableEntry: BinaryTranslationStoreGenerator {
    
    let entryData: SmartData
    let offsetInMacho: Int
    let is64Bit: Bool
    
    init(entryData: SmartData, offsetInMacho: Int, is64Bit: Bool) {
        self.entryData = entryData
        self.offsetInMacho = offsetInMacho
        self.is64Bit = is64Bit
    }
    
    func binaryTranslationStore() -> BinaryTranslationStore {
        var store = BinaryTranslationStore(data: entryData, baseDataOffset: offsetInMacho)
        store.translateNext(entryData.count) { Readable(description: "Symbol", explanation: nil) } //FIXME:
        return store
    }
}

struct SymbolTable: BinaryTranslationStoreGenerator {
    let id = UUID()
    let offsetInMacho: Int
    let entries: [SymbolTableEntry]
    var dataSize: Int { entries.reduce(0) { $0 + $1.entryData.count } }
    
    init(_ data: SmartData, offsetInMacho: Int, numberOfEntries: Int, is64Bit: Bool) {
        self.offsetInMacho = offsetInMacho
        var entries: [SymbolTableEntry] = []
        let entrySize = is64Bit ? 16 : 12
        for i in 0..<numberOfEntries {
            let nextEntryOffset = i * entrySize
            let entryData = data.select(from: nextEntryOffset, length: entrySize)
            let entry = SymbolTableEntry(entryData: entryData, offsetInMacho: offsetInMacho + nextEntryOffset, is64Bit: is64Bit)
            entries.append(entry)
        }
        self.entries = entries
    }
    
    func binaryTranslationStore() -> BinaryTranslationStore {
        var store = entries.first!.binaryTranslationStore()
        entries.dropFirst().forEach { store.merge(with: $0.binaryTranslationStore()) }
        return store
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
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType, offsetInMacho: Int) {
        var shifter = DataShifter(loadCommandData)
        _ = shifter.nextQuadWord() // skip basic data
        self.symbolTableOffset = shifter.nextDoubleWord().UInt32
        self.numberOfSymbolTableEntries = shifter.nextDoubleWord().UInt32
        self.stringTableOffset = shifter.nextDoubleWord().UInt32
        self.sizeOfStringTable = shifter.nextDoubleWord().UInt32
        super.init(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
    }
    
    override func binaryTranslationStore() -> BinaryTranslationStore {
        var store = super.binaryTranslationStore()
        store.translateNextDoubleWord { Readable(description: "Symbol table offset", explanation: "\(self.symbolTableOffset.hex)") }
        store.translateNextDoubleWord { Readable(description: "Number of entries", explanation: "\(self.numberOfSymbolTableEntries)") }
        store.translateNextDoubleWord { Readable(description: "String table offset", explanation: "\(self.stringTableOffset.hex)") }
        store.translateNextDoubleWord { Readable(description: "Size of string table", explanation: self.sizeOfStringTable.hex) }
        return store
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
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType, offsetInMacho: Int) {
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
        super.init(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
    }
    
    override func binaryTranslationStore() -> BinaryTranslationStore {
        var store = super.binaryTranslationStore()
        store.translateNextDoubleWord { Readable(description: "index to local symbols ", explanation: "\(self.ilocalsym)") }
        store.translateNextDoubleWord { Readable(description: "number of local symbols ", explanation: "\(self.nlocalsym)") }
        store.translateNextDoubleWord { Readable(description: "index to externally defined symbols ", explanation: "\(self.iextdefsym)") }
        store.translateNextDoubleWord { Readable(description: "number of externally defined symbols ", explanation: "\(self.nextdefsym)") }
        store.translateNextDoubleWord { Readable(description: "index to undefined symbols ", explanation: "\(self.iundefsym)") }
        store.translateNextDoubleWord { Readable(description: "number of undefined symbols ", explanation: "\(self.nundefsym)") }
        store.translateNextDoubleWord { Readable(description: "file offset to table of contents ", explanation: "\(self.tocoff.hex)") }
        store.translateNextDoubleWord { Readable(description: "number of entries in table of contents ", explanation: "\(self.ntoc)") }
        store.translateNextDoubleWord { Readable(description: "file offset to module table ", explanation: "\(self.modtaboff.hex)") }
        store.translateNextDoubleWord { Readable(description: "number of module table entries ", explanation: "\(self.nmodtab)") }
        store.translateNextDoubleWord { Readable(description: "offset to referenced symbol table ", explanation: "\(self.extrefsymoff.hex)") }
        store.translateNextDoubleWord { Readable(description: "number of referenced symbol table entries ", explanation: "\(self.nextrefsyms)") }
        store.translateNextDoubleWord { Readable(description: "file offset to the indirect symbol table ", explanation: "\(self.indirectsymoff.hex)") }
        store.translateNextDoubleWord { Readable(description: "number of indirect symbol table entries ", explanation: "\(self.nindirectsyms)") }
        store.translateNextDoubleWord { Readable(description: "offset to external relocation entries ", explanation: "\(self.extreloff.hex)") }
        store.translateNextDoubleWord { Readable(description: "number of external relocation entries ", explanation: "\(self.nextrel)") }
        store.translateNextDoubleWord { Readable(description: "offset to local relocation entries ", explanation: "\(self.locreloff.hex)") }
        store.translateNextDoubleWord { Readable(description: "number of local relocation entries ", explanation: "\(self.nlocrel)") }
        return store
    }
}

struct StringTable: Identifiable, BinaryTranslationStoreGenerator {
    let id = UUID()
    let offsetInMacho: Int
    let data: SmartData
    var dataSize: Int { data.count }
    let strings: [String]
    
    init(_ stringTableData: SmartData, offsetInMacho: Int) {
        self.data = stringTableData
        self.offsetInMacho = offsetInMacho
        let stringsData = stringTableData.realData.split(separator: 0)
        self.strings = stringsData.compactMap { String(data: $0, encoding: .utf8) }
    }
    
    func binaryTranslationStore() -> BinaryTranslationStore {
        var store = BinaryTranslationStore(data: data, baseDataOffset: offsetInMacho)
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
        return store
    }
}
