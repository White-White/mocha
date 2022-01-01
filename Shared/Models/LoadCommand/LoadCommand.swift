//
//  LoadCommand.swift
//  mocha
//
//  Created by white on 2021/6/17.
//

import Foundation

enum LoadCommandType: UInt32 {
    
    // ref: <mach-o/loader.h>
    /* After MacOS X 10.1 when a new load command is added that is required to be
      understood by the dynamic linker for the image to execute properly the
      LC_REQ_DYLD bit will be or'ed into the load command constant. */
    // So we remove the mask value here
    
    case segment = 0x1
    case symbolTable
    case symseg
    case thread
    case unixThread
    case loadFVMLib
    case idFVMLib
    case ident
    case FVMFile
    case prePage
    case dynamicSymbolTable
    case loadDylib
    case idDylib
    case loadDynamicLinker
    case idDynamicLinker
    case preBoundDylib
    case routines
    case subFramework
    case subUmbrella
    case subClient
    case subLibrary
    case twoLevelHints
    case prebindChecksum
    case loadWeakDylib = 0x80000018
    case segment64 = 0x19
    case routines64
    case uuid
    case rpath = 0x8000001c
    case codeSignature = 0x1d
    case segmentSplitInfo
    case reexportDylib = 0x8000001f
    case lazyLoadDylib = 0x20
    case encryptionInfo
    case dyldInfo
    case dyldInfoOnly = 0x80000022
    case loadUpwardDylib
    case macOSMinVersion = 0x24
    case iOSMinVersion
    case functionStarts
    case dyldEnvironment
    case main = 0x80000028
    case dataInCode = 0x29
    case sourceVersion
    case dylibCodeSigDRs
    case encryptionInfo64
    case linkerOption
    case linkerOptimizationHint
    case tvOSMinVersion
    case watchOSMinVersion
    case note
    case buildVersion
    case dyldExportsTrie = 0x80000033
    case dyldChainedFixups
    case fileSetEntry
    
    var commandName: String {
        switch self {
        case .segment:
            return "LC_SEGMENT"
        case .symbolTable:
            return "LC_SYMTAB"
        case .symseg:
            return "LC_SYMSEG"
        case .thread:
            return "LC_THREAD"
        case .unixThread:
            return "LC_UNIXTHREAD"
        case .loadFVMLib:
            return "LC_LOADFVMLIB"
        case .idFVMLib:
            return "LC_IDFVMLIB"
        case .ident:
            return "LC_IDENT"
        case .FVMFile:
            return "LC_FVMFILE"
        case .prePage:
            return "LC_PREPAGE"
        case .dynamicSymbolTable:
            return "LC_DYSYMTAB"
        case .loadDylib:
            return "LC_LOAD_DYLIB"
        case .idDylib:
            return "LC_ID_DYLIB"
        case .loadDynamicLinker:
            return "LC_LOAD_DYLINKER"
        case .idDynamicLinker:
            return "LC_ID_DYLINKER"
        case .preBoundDylib:
            return "LC_PREBOUND_DYLIB"
        case .routines:
            return "LC_ROUTINES"
        case .subFramework:
            return "LC_SUB_FRAMEWORK"
        case .subUmbrella:
            return "LC_SUB_UMBRELLA"
        case .subClient:
            return "LC_SUB_CLIENT"
        case .subLibrary:
            return "LC_SUB_LIBRARY"
        case .twoLevelHints:
            return "LC_TWOLEVEL_HINTS"
        case .prebindChecksum:
            return "LC_PREBIND_CKSUM"
        case .loadWeakDylib:
            return "LC_LOAD_WEAK_DYLIB"
        case .segment64:
            return "LC_SEGMENT_64"
        case .routines64:
            return "LC_ROUTINES_64"
        case .uuid:
            return "LC_UUID"
        case .rpath:
            return "LC_RPATH"
        case .codeSignature:
            return "LC_CODE_SIGNATURE"
        case .segmentSplitInfo:
            return "LC_SEGMENT_SPLIT_INFO"
        case .reexportDylib:
            return "LC_REEXPORT_DYLIB"
        case .lazyLoadDylib:
            return "LC_LAZY_LOAD_DYLIB"
        case .encryptionInfo:
            return "LC_ENCRYPTION_INFO"
        case .dyldInfo:
            return "LC_DYLD_INFO"
        case .dyldInfoOnly:
            return "LC_DYLD_INFO_ONLY"
        case .loadUpwardDylib:
            return "LC_LOAD_UPWARD_DYLIB"
        case .macOSMinVersion:
            return "LC_VERSION_MIN_MACOSX"
        case .iOSMinVersion:
            return "LC_VERSION_MIN_IPHONEOS"
        case .functionStarts:
            return "LC_FUNCTION_STARTS"
        case .dyldEnvironment:
            return "LC_DYLD_ENVIRONMENT"
        case .main:
            return "LC_MAIN"
        case .dataInCode:
            return "LC_DATA_IN_CODE"
        case .sourceVersion:
            return "LC_SOURCE_VERSION"
        case .dylibCodeSigDRs:
            return "LC_DYLIB_CODE_SIGN_DRS"
        case .encryptionInfo64:
            return "LC_ENCRYPTION_INFO_64"
        case .linkerOption:
            return "LC_LINKER_OPTION"
        case .linkerOptimizationHint:
            return "LC_LINKER_OPTIMIZATION_HINT"
        case .tvOSMinVersion:
            return "LC_VERSION_MIN_TVOS"
        case .watchOSMinVersion:
            return "LC_VERSION_MIN_WATCHOS"
        case .note:
            return "LC_NOTE"
        case .buildVersion:
            return "LC_BUILD_VERSION"
        case .dyldExportsTrie:
            return "LC_DYLD_EXPORTS_TRIE"
        case .dyldChainedFixups:
            return "LC_DYLD_CHAINED_FIXUPS"
        case .fileSetEntry:
            return "LC_FILESET_ENTRY"
        }
    }
}

class LoadCommand: SmartDataContainer, TranslationStoreDataSource {
    
    let loadCommandType: LoadCommandType
    let smartData: SmartData
    var translationDividerName: String? { nil }
    
    var primaryName: String { loadCommandType.commandName }
    var secondaryName: String { "Load Command" }
    
    init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        self.smartData = loadCommandData
        self.loadCommandType = loadCommandType
    }
    
    static func loadCommand(with data: SmartData) -> LoadCommand {
        
        let loadCommandTypeValue = data.truncated(from: 0, length: 4).raw.UInt32
        guard let type = LoadCommandType(rawValue: loadCommandTypeValue) else {
            print("Unknown load command type \(loadCommandTypeValue.hex). This must be a new one.")
            fatalError()
        }
        
        switch type {
        case .iOSMinVersion, .macOSMinVersion, .tvOSMinVersion, .watchOSMinVersion:
            return MinOSVersion(with: data, loadCommandType: type)
        case .linkerOption:
            return LCLinkerOption(with: data, loadCommandType: type)
        case .segment, .segment64:
            return Segment(with: data, loadCommandType: type)
        case .symbolTable:
            return LCSymbolTable(with: data, loadCommandType: type)
        case .dynamicSymbolTable:
            return LCDynamicSymbolTable(with: data, loadCommandType: type)
        case .idDylib, .loadDylib, .loadWeakDylib, .reexportDylib, .lazyLoadDylib, .loadUpwardDylib:
            return Dylib(with: data, loadCommandType: type)
        case .rpath:
            return LCOneString(with: data, loadCommandType: type, description: "rpath")
        case .idDynamicLinker:
            return LCOneString(with: data, loadCommandType: type, description: "Dynamic Linker ID")
        case .loadDynamicLinker:
            return LCOneString(with: data, loadCommandType: type, description: "Dynamic Linker")
        case .dyldEnvironment:
            return LCOneString(with: data, loadCommandType: type, description: "Dynamic Linker Env")
        case .uuid:
            return LCUUID(with: data, loadCommandType: type)
        case .sourceVersion:
            return LCSourceVersion(with: data, loadCommandType: type)
        case .dataInCode:
            return LinkedITData(with: data, loadCommandType: type, dataName: "Data in Code", translatorType: ModelTranslator<DataInCodeModel>.self)
        case .codeSignature:
            return LinkedITData(with: data, loadCommandType: type, dataName: "Code Signature", translatorType: CodeTranslator.self)
        default:
            Log.warning("Unknown load command \(type.commandName). Debug me.")
            return LoadCommand(with: data, loadCommandType: type)
        }
    }
    
    var numberOfTranslationSections: Int { 1 }
    
    func translationSection(at index: Int) -> TransSection {
        guard index == 0 else { fatalError() }
        let section = TransSection(baseIndex: smartData.startOffsetInMacho, title: "Load Command")
        section.translateNextDoubleWord { Readable(description: "Load Command Type", explanation: "\(self.loadCommandType.commandName)") }
        section.translateNextDoubleWord { Readable(description: "Size", explanation: self.smartData.count.hex) }
        return section
    }
}









class LCOneString: LoadCommand {
    
    let stringOffset: UInt32
    let string: String
    let description: String
    
    init(with loadCommandData: SmartData, loadCommandType: LoadCommandType, description: String) {
        var shifter = DataShifter(loadCommandData)
        _ = shifter.nextQuadWord() // skip basic data
        let stringOffset = shifter.nextDoubleWord().UInt32
        self.stringOffset = stringOffset
        if let string = loadCommandData.truncated(from: Int(stringOffset)).raw.utf8String {
            self.string = string.spaceRemoved
        } else {
            self.string = Log.warning("Failed to parse \(description). Debug me.")
        }
        self.description = description
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "String Offset", explanation: "\(self.stringOffset)") }
        section.translateNext(string.count) { Readable(description: self.description, explanation: self.string) }
        return section
    }
}

class LCUUID: LoadCommand {
    
    let uuid: UUID
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        let uuidData = loadCommandData.truncated(from: 8).raw.map { UInt8($0) }
        self.uuid = UUID(uuid: (uuidData[0], uuidData[1], uuidData[2], uuidData[3], uuidData[4], uuidData[5], uuidData[6], uuidData[7],
                                  uuidData[8], uuidData[9], uuidData[10], uuidData[11], uuidData[12], uuidData[13], uuidData[14], uuidData[15]))
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNext(16) { Readable(description: "UUID", explanation: self.uuid.uuidString) }
        return section
    }
}

class LCSourceVersion: LoadCommand {
    
    let version: String
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        let versionValue = loadCommandData.truncated(from: 8).raw.UInt64
        /* A.B.C.D.E packed as a24.b10.c10.d10.e10 */
        let mask: Swift.UInt64 = 0x3ff
        let e = versionValue & mask
        let d = (versionValue >> 10) & mask
        let c = (versionValue >> 20) & mask
        let b = (versionValue >> 30) & mask
        let a = versionValue >> 40
        self.version = String(format: "%d.%d.%d.%d.%d", a, b, c, d, e)
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNext(8) { Readable(description: "Source Version", explanation: self.version) }
        return section
    }
}
