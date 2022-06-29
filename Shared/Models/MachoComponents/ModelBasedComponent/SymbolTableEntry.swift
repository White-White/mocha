//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/15.
//

import Foundation

enum StabType: UInt8 {
    case gsym = 0x20    /* global symbol */
    case fname = 0x22    /* F77 function name */
    case fun = 0x24    /* procedure name */
    case stsym = 0x26    /* data segment variable */
    case lcsym = 0x28    /* bss segment variable */
    case main = 0x2a    /* main function name */
    case pc = 0x30    /* global Pascal symbol */
    case rsym = 0x40    /* register variable */
    case sline = 0x44    /* text segment line number */
    case dsline = 0x46    /* data segment line number */
    case bsline = 0x48    /* bss segment line number */
    case ssym = 0x60    /* structure/union element */
    case sol = 0x64    /* main source file name */
    case lsym = 0x80    /* stack variable */
    case bincl = 0x82    /* include file beginning */
    case so = 0x84    /* included source file name */
    case psym = 0xa0    /* parameter variable */
    case eincl = 0xa2    /* include file end */
    case entry = 0xa4    /* alternate entry point */
    case lbrac = 0xc0    /* left bracket */
    case excl = 0xc2    /* deleted include file */
    case rbrac = 0xe0    /* right bracket */
    case bcomm = 0xe2    /* begin common */
    case ecomm = 0xe4    /* end common */
    case ecoml = 0xe8    /* end common (local name) */
    case leng = 0xfe    /* length of preceding entry */
    
    var readable: String {
        switch self {
        case .gsym:
            return "N_GSYM"
        case .fname:
            return "N_FNAME"
        case .fun:
            return "N_FUN"
        case .stsym:
            return "N_STSYM"
        case .lcsym:
            return "N_LCSYM"
        case .main:
            return "N_MAIN"
        case .pc:
            return "N_PC"
        case .rsym:
            return "N_RSYM"
        case .sline:
            return "N_SLINE"
        case .dsline:
            return "N_DSLINE"
        case .bsline:
            return "N_BSLINE"
        case .ssym:
            return "N_SSYM"
        case .so:
            return "N_SO"
        case .lsym:
            return "N_LSYM"
        case .bincl:
            return "N_BINCL"
        case .sol:
            return "N_SOL"
        case .psym:
            return "N_PSYM"
        case .eincl:
            return "N_EINCL"
        case .entry:
            return "N_ENTRY"
        case .lbrac:
            return "N_LBRAC"
        case .excl:
            return "N_EXCL"
        case .rbrac:
            return "N_RBRAC"
        case .bcomm:
            return "N_BCOMM"
        case .ecomm:
            return "N_ECOMM"
        case .ecoml:
            return "N_ECOML"
        case .leng:
            return "N_LENG"
        }
    }
}

enum SymbolType: Equatable {
    case stab(StabType?)
    case undefined
    case absolute
    case section
    case preBound
    case indirect
    
    var readable: String {
        switch self {
        case .stab(_):
            return "N_STAB" // FIXME: ignoring detailed stab type
        case .undefined:
            return "Undefined Symbol (N_UNDF)"
        case .absolute:
            return "Absolute Symbol (N_ABS)"
        case .section:
            return "Defined in "
        case .preBound:
            return "Prebound undefined (N_PBUD)"
        case .indirect:
            return "Indirect Symbol (N_INDR)"
        }
    }
    
    init(nTypeRaw: UInt8) {
        if (nTypeRaw & 0xe0) != 0 {
            let stabType = StabType(rawValue: nTypeRaw)
            self = .stab(stabType)
        } else {
            let n_type_filed = nTypeRaw & 0x0e /* 0x0e == N_TYPE mask == 00001110 */
            switch n_type_filed {
            case 0x0:
                self = .undefined // N_UNDF    0x0        /* undefined, n_sect == NO_SECT */
            case 0x2:
                self = .absolute // N_ABS    0x2        /* absolute, n_sect == NO_SECT */
            case 0xe:
                self = .section // N_SECT    0xe        /* defined in section number n_sect */
            case 0xc:
                self = .preBound // N_PBUD    0xc        /* prebound undefined (defined in a dylib) */
            case 0xa:
                self = .indirect // N_INDR    0xa        /* indirect */
            default:
                /* Unlikely. it must be a symbol */
                fatalError()
            }
        }
    }
}

struct SymbolTableEntry: InterpretableModel {
    
    weak var macho: Macho?
    
    let indexInStringTableRange: Range<Int>
    let indexInStringTable: UInt32
    
    let symbolType: SymbolType
    
    /*
     ref: http://mirror.informatimago.com/next/developer.apple.com/documentation/DeveloperTools/Conceptual/MachORuntime/8rt_file_format/chapter_10_section_24.html
     N_PEXT (0x10). If this bit is on, this symbol is marked as having limited global scope. When the file is fed to the static linker, it clears the N_EXT bit for each symbol with the N_PEXT bit set. (The ld option -keep_private_externs disables this behavior.) With Mac OS X GCC, you can use the __private_extern__ function attribute to set this bit.
     
     ref: https://lists.llvm.org/pipermail/cfe-dev/2008-November/003249.html
     A private external symbol is a defined external symbol that is visible
     only to other modules within the same object file as the module that
     contains it. The standard static linker changes private external
     symbols into private defined symbols unless you specify otherwise
     (using the -keep_private_externs flag).
     You can mark a symbol as private external by using the
     __private_extern__ keyword (which works only in C) or the
     visibility("hidden")attribute (which works both in C and C++ with GCC
     4.0), as in this example:
     
     __private_extern__ int x = 0;                       // C only
     int y = 99 __attribute__((visibility("hidden")));   // C and C++, GCC
     4.0 only
     */
    let isPrivateExternalSymbol: Bool
    
    let isExternalSymbol: Bool
    
    let nSect: UInt8
    let nDesc: Swift.UInt16
    let nValue: UInt64
    
    let translaitonItems: [TranslationItem]
    
    init(with data: DataSlice, is64Bit: Bool, macho: Macho) {
        
        self.macho = macho
        
        var translaitonItems: [TranslationItem] = []
        
        let indexInStringTable = data.truncated(from: .zero, length: 4).raw.UInt32
        self.indexInStringTable = indexInStringTable
        self.indexInStringTableRange = data.absoluteRange(.zero, 4)
        
        /*
         * n_type
         * The n_type field really contains four fields:
         *    unsigned char N_STAB:3, if any of these bits set, a symbolic debugging entry
         *              N_PEXT:1,
         *              N_TYPE:3,
         *              N_EXT:1;
         * which are used via the following masks.
         */
        
        let nTypeByteRange = data.absoluteRange(4, 1)
        let nTypeRaw = data.truncated(from: 4, length: 1).raw.UInt8
        let symbolType = SymbolType(nTypeRaw: nTypeRaw)
        self.symbolType = symbolType
        
        let isPrivateExternalSymbol = (nTypeRaw & 0x10) != 0 // 0x10 == N_PEXT mask == 00010000 /* private external symbol bit */
        self.isPrivateExternalSymbol = isPrivateExternalSymbol
        let isExternalSymbol = (nTypeRaw & 0x01) != 0 // 0x01 == N_EXT mask == 00000001 /* external symbol bit, set for external symbols */
        self.isExternalSymbol = isExternalSymbol
        
        /*
         * n_sect
         * n_desc
         * n_value
         */
        
        let nSect = data.truncated(from: 5, length: 1).raw.UInt8
        let nDesc = data.truncated(from: 6, length: 2).raw.UInt16
        let nValueRawData = data.truncated(from: 8, length: is64Bit ? 8 : 4).raw
        let nValue = is64Bit ? nValueRawData.UInt64 : UInt64(nValueRawData.UInt32)
        self.nSect = nSect
        self.nDesc = nDesc
        self.nValue = nValue
        
        let symbolTypeDesp: String = "Symbol Type"
        var symbolTypeExplanation: String = symbolType.readable
        
        let nSectDesp: String = "Section Ordinal"
        var nSectExplanation: String = "\(nSect)"
        
        let nDescDesp: String = "Descriptions"
        let nDescExplanation: String = SymbolTableEntry.flagsFrom(nDesc: nDesc, symbolType: symbolType).joined(separator: "\n")
        
        var nValueDesp: String = "Value"
        var nValueExplanation: String = "\(nValue)"
        var nValueExtraDesp: String?
        var nValueExtraExplanation: String?
        
        switch symbolType {
        case .undefined:
            nSectExplanation = "0 (NO_SECT)"
        case .absolute:
            nSectExplanation = "0 (NO_SECT)"
        case .section:
            symbolTypeExplanation += (self.macho!.sectionName(at: Int(nSect)) + " (N_SECT)")
        case .indirect:
            nValueDesp = "String table offset"
            nValueExplanation = nValue.hex
            nValueExtraDesp = "Referred string"
            nValueExtraExplanation = self.macho!.stringInStringTable(at: Int(nValue))
        default:
            break
        }
        
        translaitonItems.append(TranslationItem(sourceDataRange: nTypeByteRange,
                                                content: TranslationItemContent(description: symbolTypeDesp,
                                                                                explanation: symbolTypeExplanation)))
        
        translaitonItems.append(TranslationItem(sourceDataRange: nTypeByteRange,
                                                content: TranslationItemContent(description: "Private External / External",
                                                                                explanation: "\(isPrivateExternalSymbol) / \(isExternalSymbol)")))
        
        translaitonItems.append(TranslationItem(sourceDataRange: data.absoluteRange(5, 1),
                                                content: TranslationItemContent(description: nSectDesp,
                                                                                explanation: nSectExplanation)))
        
        translaitonItems.append(TranslationItem(sourceDataRange: data.absoluteRange(6, 2),
                                                content: TranslationItemContent(description: nDescDesp,
                                                                                explanation: nDescExplanation)))
        
        translaitonItems.append(TranslationItem(sourceDataRange: data.absoluteRange(8, is64Bit ? 8 : 4),
                                                content: TranslationItemContent(description: nValueDesp, explanation: nValueExplanation,
                                                                                extraDescription: nValueExtraDesp, extraExplanation: nValueExtraExplanation,
                                                                                hasDivider: true)))
        
        self.translaitonItems = translaitonItems
    }
    
    static func flagsFrom(nDesc: UInt16, symbolType: SymbolType) -> [String] {
        // FIXME: the code below for pasing n_desc is far from complete, less alone correct
        // it takes more effort to read llvm-nm and other sources to finally create good codes
        
        var flags: [String] = []
        
        switch symbolType {
        case .undefined:
            fallthrough
        case .preBound:
            let referenceType = nDesc & 0x7
            switch referenceType {
            case 0:
                flags.append("REFERENCE_FLAG_UNDEFINED_NON_LAZY")
            case 1:
                flags.append("REFERENCE_FLAG_UNDEFINED_LAZY")
            case 2:
                flags.append("REFERENCE_FLAG_DEFINED")
            case 3:
                flags.append("REFERENCE_FLAG_PRIVATE_DEFINED")
            case 4:
                flags.append("REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY")
            case 5:
                flags.append("REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY")
            default:
                break
            }
            
            let libraryOrdinal = (nDesc >> 8) & 0xff
            switch libraryOrdinal {
            case 0x0:
                flags.append("SELF_LIBRARY_ORDINAL")
            case 0xfd:
                flags.append("MAX_LIBRARY_ORDINAL")
            case 0xfe:
                flags.append("DYNAMIC_LOOKUP_ORDINAL")
            case 0xff:
                flags.append("EXECUTABLE_ORDINAL")
            default:
                break
            }
        default:
            break
        }
        
        if nDesc & 0x0010 != 0 {
            flags.append("REFERENCED_DYNAMICALLY")
        }
        
        if nDesc & 0x0020 != 0 {
            flags.append("N_NO_DEAD_STRIP")
        }
        
        if nDesc & 0x0040 != 0 {
            flags.append("N_WEAK_REF")
        }
        
        switch symbolType {
        case .undefined:
            if nDesc & 0x0080 != 0 {
                flags.append("N_REF_TO_WEAK")
            }
        default:
            if nDesc & 0x0080 != 0 {
                flags.append("N_WEAK_DEF")
            }
            if nDesc & 0x0100 != 0 {
                flags.append("N_SYMBOL_RESOLVER")
            }
        }
        
        if nDesc & 0x0008 != 0 {
            flags.append("N_ARM_THUMB_DEF")
        }
        
        if flags.isEmpty {
            flags.append("NONE")
        }
        
        return flags
    }
    
    func translationItem(at index: Int) -> TranslationItem {
        
        // string searching takes too much time. so make it lazy
        if index == 0 {
            let symbolName: String
            if indexInStringTable == 0 {
                symbolName = "" // if zero, means empty string
            } else {
                guard let symbolStringFromStringTable = macho?.stringInStringTable(at: Int(indexInStringTable)) else {
                    fatalError() /* didn't find symbol string. unexpected */
                }
                symbolName = symbolStringFromStringTable
            }
            
            return TranslationItem(sourceDataRange: indexInStringTableRange,
                                   content: TranslationItemContent(description: "String table offset", explanation: indexInStringTable.hex,
                                                                   extraDescription: "Symbol Name", extraExplanation: symbolName))
        }
        
        return translaitonItems[index - 1]
    }
    
    static func modelSize(is64Bit: Bool) -> Int {
        return is64Bit ? 16 : 12
    }
    
    static func numberOfTranslationItems() -> Int {
        return 6
    }
}
