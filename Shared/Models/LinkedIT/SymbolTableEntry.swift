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
    
    let indexInStringTable: UInt32
    // flags
    let symbolType: SymbolType
    let isPrivateExternalSymbol: Bool
    let isExternalSymbol: Bool
    
    let sectionNumber: UInt8
    let n_desc: Swift.UInt16
    let n_value: UInt64
    
    let translationStore: TranslationStore
    
    init(with data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey : Any]? = nil) {
        
        let translationStore = TranslationStore(machoDataSlice: data, sectionTitle: nil)
        
        self.indexInStringTable = translationStore.translate(next: .doubleWords,
                                                           dataInterpreter: DataInterpreterPreset.UInt32,
                                                           itemContentGenerator: { indexInStringTable in
            let demangledString = (settings?[.stringTableSearchingDelegate] as? StringTableSearchingDelegate)?.searchStringTable(with: Int(indexInStringTable))?.value
            return TranslationItemContent(description: "String table index", explanation: indexInStringTable.hex, extraExplanation: demangledString)
        })
        
        /*
         * The n_type field really contains four fields:
         *    unsigned char N_STAB:3,
         *              N_PEXT:1,
         *              N_TYPE:3,
         *              N_EXT:1;
         * which are used via the following masks.
         */
        
        let flagsValue = data.truncated(from: 4, length: 1).raw.first! // n_type field
        let flagsByteRange = data.absoluteRange(4, 1)
        
        let symbolType: SymbolType
        if (flagsValue & 0xe0) != 0 { // 0xe0 == N_STAB mask == 01110000
            symbolType = .debugging
        } else {
            let valueN_TYPE = flagsValue & 0x0e // 0x0e == N_TYPE mask == 00001110
            switch valueN_TYPE {
            case 0x0: // N_UNDF    0x0        /* undefined, n_sect == NO_SECT */
                symbolType = .undefined
            case 0x2: // N_ABS    0x2        /* absolute, n_sect == NO_SECT */
                symbolType = .absolute
            case 0xe: // N_SECT    0xe        /* defined in section number n_sect */
                symbolType = .section
            case 0xc: // N_PBUD    0xc        /* prebound undefined (defined in a dylib) */
                symbolType = .preBound
            case 0xa: // N_INDR    0xa        /* indirect */
                symbolType = .indirect
            default:
                fatalError()
            }
        }
        self.symbolType = symbolType
        
        let valueN_PEXT = (flagsValue & 0x10) != 0 // 0x10 == N_PEXT mask == 00010000 /* private external symbol bit */
        let valueN_EXT = (flagsValue & 0x01) != 0 // 0x01 == N_EXT mask == 00000001 /* external symbol bit, set for external symbols */
        self.isPrivateExternalSymbol = valueN_PEXT
        self.isExternalSymbol = valueN_EXT
        
        translationStore.append(TranslationItemContent(description: "Type", explanation: symbolType.name), forRange: flagsByteRange)
        translationStore.append(TranslationItemContent(description: "Private External", explanation: "\(valueN_PEXT)"), forRange: flagsByteRange)
        translationStore.append(TranslationItemContent(description: "External", explanation: "\(valueN_EXT)"), forRange: flagsByteRange)
        _ = translationStore.skip(.rawNumber(1))
        
        self.sectionNumber = translationStore.translate(next: .rawNumber(1),
                                                      dataInterpreter: { $0.first! },
                                                      itemContentGenerator: { sectionNumber in TranslationItemContent(description: "Section Number", explanation: "\(sectionNumber)") })
        
        self.n_desc = translationStore.translate(next: .word,
                                               dataInterpreter: { $0.UInt16 },
                                               itemContentGenerator: { n_desc in TranslationItemContent(description: "n_desc", explanation: n_desc.hex) })
        
        self.n_value = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                               dataInterpreter: { $0.UInt64 },
                                               itemContentGenerator: { n_value in TranslationItemContent(description: "n_value", explanation: n_value.hex) })
        
        self.translationStore = translationStore
    }
    
    func translationItem(at index: Int) -> TranslationItem {
        return translationStore.items[index]
    }
    
    static func modelSize(is64Bit: Bool) -> Int {
        return is64Bit ? 16 : 12
    }
    
    static func numberOfTranslationItems() -> Int {
        return 7
    }
}

struct DynamicSymbolTableEntry {
    
}
