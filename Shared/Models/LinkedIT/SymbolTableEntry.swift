//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/15.
//

import Foundation

enum SymbolType {
    case debugging
    
    case undefined
    case absolute
    case section
    case preBound
    case indirect
    
    var name: String {
        switch self {
        case .debugging:
            return "Debugging Symbol (N_STAB)"
        case .undefined:
            return "Undefined Symbol (N_UNDF)"
        case .absolute:
            return "Absolute Symbol (N_ABS)"
        case .section:
            return "Defined in section n_sect (N_SECT)"
        case .preBound:
            return "Prebound undefined (N_PBUD)"
        case .indirect:
            return "Indirect Symbol (N_INDR)"
        }
    }
}

struct SymbolTableEntry: InterpretableModel {
    
    let data: DataSlice
    let is64Bit: Bool
    weak var stringTableSearchingDelegate: StringTableSearchingDelegate?
    
    let indexInStringTable: UInt32
    
    // flags
    let symbolType: SymbolType
    let isPrivateExternalSymbol: Bool
    let isExternalSymbol: Bool
    
    let sectionNumber: UInt8
    let n_desc: Swift.UInt16
    let n_value: UInt64
    
    
    init(with data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey : Any]? = nil) {
        self.data = data
        self.is64Bit = is64Bit
        self.stringTableSearchingDelegate = settings?[.stringTableSearchingDelegate] as? StringTableSearchingDelegate
        
        var shifter = DataShifter(data)
        self.indexInStringTable = shifter.nextDoubleWord().UInt32
        
        /*
         * The n_type field really contains four fields:
         *    unsigned char N_STAB:3,
         *              N_PEXT:1,
         *              N_TYPE:3,
         *              N_EXT:1;
         * which are used via the following masks.
         */
        
        let flagsValue = shifter.shift(1).first! // n_type field
        
        if (flagsValue & 0xe0) != 0 { // 0xe0 == N_STAB mask == 01110000
            self.symbolType = .debugging
        } else {
            let valueN_TYPE = flagsValue & 0x0e // 0x0e == N_TYPE mask == 00001110
            switch valueN_TYPE {
            case 0x0: // N_UNDF    0x0        /* undefined, n_sect == NO_SECT */
                self.symbolType = .undefined
            case 0x2: // N_ABS    0x2        /* absolute, n_sect == NO_SECT */
                self.symbolType = .absolute
            case 0xe: // N_SECT    0xe        /* defined in section number n_sect */
                self.symbolType = .section
            case 0xc: // N_PBUD    0xc        /* prebound undefined (defined in a dylib) */
                self.symbolType = .preBound
            case 0xa: // N_INDR    0xa        /* indirect */
                self.symbolType = .indirect
            default:
                fatalError()
            }
        }
        
        let valueN_PEXT = (flagsValue & 0x10) != 0 // 0x10 == N_PEXT mask == 00010000 /* private external symbol bit */
        let valueN_EXT = (flagsValue & 0x01) != 0 // 0x01 == N_EXT mask == 00000001 /* external symbol bit, set for external symbols */
        self.isPrivateExternalSymbol = valueN_PEXT
        self.isExternalSymbol = valueN_EXT
        
        let sectionNumber = shifter.shift(1).first!
        self.sectionNumber = sectionNumber
        
        let n_desc = shifter.shift(2).UInt16
        self.n_desc = n_desc
        
        let n_value = shifter.shift(is64Bit ? 8 : 4).UInt64
        self.n_value = n_value
    }
    
    func makeTransSection() -> TransSection {
        let section = TransSection(baseIndex: data.startIndex, title: nil)
        section.addTranslation(forRange: 0..<4) {
            let cStringSearchingResult = self.stringTableSearchingDelegate?.searchStringTable(with: Int(self.indexInStringTable))
            let referredCString = cStringSearchingResult?.value ?? "Didn't find"
            return Readable(description: "String table index",
                            explanation: "\(self.indexInStringTable.hex)",
                            extraExplanation: "Referred string: \(referredCString)")
        }
        
        section.addTranslation(forRange: 4..<5) { Readable(description: "Type", explanation: self.symbolType.name) }
        section.addTranslation(forRange: 1..<2) { Readable(description: "Private External", explanation: "\(self.isPrivateExternalSymbol)") } // FIXME: range bug
        section.addTranslation(forRange: 2..<3) { Readable(description: "External", explanation: "\(self.isExternalSymbol)") } // FIXME: range bug
        section.addTranslation(forRange: 5..<7) { Readable(description: "n_desc", explanation: "\(self.n_desc.hex)") }
        section.addTranslation(forRange: 8..<(self.is64Bit ? 16 : 12)) { Readable(description: "n_value", explanation: "\(self.n_value.hex)") }
        return section
    }
    
    static func modelSize(is64Bit: Bool) -> Int {
        return is64Bit ? 16 : 12
    }
}

struct DynamicSymbolTable {
    
}
