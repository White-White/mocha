//
//  LCDynamicSymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/11.
//

import Foundation

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
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.ilocalsym = dataShifter.shiftUInt32()
        self.nlocalsym = dataShifter.shiftUInt32()
        self.iextdefsym = dataShifter.shiftUInt32()
        self.nextdefsym = dataShifter.shiftUInt32()
        self.iundefsym = dataShifter.shiftUInt32()
        self.nundefsym = dataShifter.shiftUInt32()
        self.tocoff = dataShifter.shiftUInt32()
        self.ntoc = dataShifter.shiftUInt32()
        self.modtaboff = dataShifter.shiftUInt32()
        self.nmodtab = dataShifter.shiftUInt32()
        self.extrefsymoff = dataShifter.shiftUInt32()
        self.nextrefsyms = dataShifter.shiftUInt32()
        self.indirectsymoff = dataShifter.shiftUInt32()
        self.nindirectsyms = dataShifter.shiftUInt32()
        self.extreloff = dataShifter.shiftUInt32()
        self.nextrel = dataShifter.shiftUInt32()
        self.locreloff = dataShifter.shiftUInt32()
        self.nlocrel = dataShifter.shiftUInt32()
        super.init(data, type: type)
    }
    
    override var commandTranslations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(description: "Start Index of Local Symbols ", explanation: "\(self.ilocalsym)", bytesCount: 4))
        translations.append(Translation(description: "Number of Local Symbols ", explanation: "\(self.nlocalsym)", bytesCount: 4))
        translations.append(Translation(description: "Start Index of External Defined Symbols ", explanation: "\(self.iextdefsym)", bytesCount: 4))
        translations.append(Translation(description: "Number of External Defined Symbols ", explanation: "\(self.nextdefsym )", bytesCount: 4))
        translations.append(Translation(description: "Start Index of Undefined Symbols ", explanation: "\(self.iundefsym)", bytesCount: 4))
        translations.append(Translation(description: "Number of Undefined Symbols ", explanation: "\(self.nundefsym)", bytesCount: 4))
        translations.append(Translation(description: "file offset to table of contents ", explanation: "\(self.tocoff.hex)", bytesCount: 4))
        translations.append(Translation(description: "number of entries in table of contents ", explanation: "\(self.ntoc)", bytesCount: 4))
        translations.append(Translation(description: "file offset to module table ", explanation: "\(self.modtaboff.hex)", bytesCount: 4))
        translations.append(Translation(description: "number of module table entries ", explanation: "\(self.nmodtab)", bytesCount: 4))
        translations.append(Translation(description: "offset to referenced symbol table ", explanation: "\(self.extrefsymoff.hex)", bytesCount: 4))
        translations.append(Translation(description: "number of referenced symbol table entries ", explanation: "\(self.nextrefsyms)", bytesCount: 4))
        translations.append(Translation(description: "file offset to the indirect symbol table ", explanation: "\(self.indirectsymoff.hex)", bytesCount: 4))
        translations.append(Translation(description: "number of indirect symbol table entries ", explanation: "\(self.nindirectsyms)", bytesCount: 4))
        translations.append(Translation(description: "offset to external relocation entries ", explanation: "\(self.extreloff.hex)", bytesCount: 4))
        translations.append(Translation(description: "number of external relocation entries ", explanation: "\(self.nextrel)", bytesCount: 4))
        translations.append(Translation(description: "offset to local relocation entries ", explanation: "\(self.locreloff.hex)", bytesCount: 4))
        translations.append(Translation(description: "number of local relocation entries ", explanation: "\(self.nlocrel)", bytesCount: 4))
        return translations
    }
    
    func indirectSymbolTable(machoData: Data, machoHeader: MachoHeader) -> IndirectSymbolTable? {
        let is64Bit = machoHeader.is64Bit
        let indirectSymbolTableStartOffset = Int(self.indirectsymoff)
        let indirectSymbolTableSize = Int(self.nindirectsyms * 4)
        if indirectSymbolTableSize == .zero { return nil }
        let indirectSymbolTableData = machoData.subSequence(from: indirectSymbolTableStartOffset, count: indirectSymbolTableSize)
        return IndirectSymbolTable(indirectSymbolTableData, title: "Indirect Symbol Table", subTitle: Constants.segmentNameLINKEDIT, is64Bit: is64Bit)
    }
    
}
