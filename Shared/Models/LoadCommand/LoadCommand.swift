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
    
    var name: String {
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

class LoadCommand: MachoComponent {
    
    let type: LoadCommandType
    let itemsContainer: TranslationItemContainer
    
    override var componentTitle: String { "Load Command" }
    override var componentSubTitle: String { type.name }
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        self.type = type
        let itemsContainer = itemsContainer ?? TranslationItemContainer(machoDataSlice: data.truncated(from: 0, length: 8), sectionTitle: nil)
        itemsContainer.insert(TranslationItemContent(description: "Size", explanation: data.count.hex), forRange: data.absoluteRange(4, 4), at: .zero)
        itemsContainer.insert(TranslationItemContent(description: "Load Command Type", explanation: type.name), forRange: data.absoluteRange(0, 4), at: .zero)
        self.itemsContainer = itemsContainer
        super.init(data)
    }
    
    override func numberOfTranslationSections() -> Int {
        return 1
    }
    
    override func translationItems(at section: Int) -> [TranslationItem] {
        return itemsContainer.items
    }
    
    static func loadCommands(from allLoadCommandData: DataSlice, numberOfLoadCommands: Int) -> [LoadCommand] {
        var loadCommands: [LoadCommand] = []
        for _ in 0..<numberOfLoadCommands {
            let nextLoadCommandStartIndex = loadCommands.reduce(.zero) { $0 + $1.size }
            let typeValue = allLoadCommandData.truncated(from: nextLoadCommandStartIndex, length: 4).raw.UInt32
            guard let type = LoadCommandType(rawValue: typeValue) else {
                print("Unknown load command type \(typeValue.hex). This must be a new one.")
                fatalError()
            }
            
            let loadCommandSize = Int(allLoadCommandData.truncated(from: nextLoadCommandStartIndex + 4, length: 4).raw.UInt32)
            let loadCommandData = allLoadCommandData.truncated(from: nextLoadCommandStartIndex, length: loadCommandSize)
            
            let loadCommandClass: LoadCommand.Type
            switch type {
            case .iOSMinVersion, .macOSMinVersion, .tvOSMinVersion, .watchOSMinVersion:
                loadCommandClass = MinOSVersion.self
            case .linkerOption:
                loadCommandClass = LinkerOption.self
            case .segment, .segment64:
                loadCommandClass = Segment.self
            case .symbolTable:
                loadCommandClass = SymbolTable.self
            case .dynamicSymbolTable:
                loadCommandClass = DynamicSymbolTable.self
            case .idDylib, .loadDylib, .loadWeakDylib, .reexportDylib, .lazyLoadDylib, .loadUpwardDylib:
                loadCommandClass = Dylib.self
            case .rpath, .idDynamicLinker, .loadDynamicLinker, .dyldEnvironment:
                loadCommandClass = LCOneString.self
            case .uuid:
                loadCommandClass = LCUUID.self
            case .sourceVersion:
                loadCommandClass = LCSourceVersion.self
            case .dataInCode, .codeSignature, .functionStarts:
                loadCommandClass = LinkedITData.self
            case .main:
                loadCommandClass = LCMain.self
            case .dyldInfo, .dyldInfoOnly:
                loadCommandClass = LCDyldInfo.self
            default:
                Log.warning("Unknown load command \(type.name). Debug me.")
                loadCommandClass = LoadCommand.self
            }
            let loadCommandInstance = loadCommandClass.init(with: type, data: loadCommandData)
            loadCommands.append(loadCommandInstance)
        }
        
        return loadCommands
    }
}

class LCOneString: LoadCommand {
    
    let stringOffset: UInt32
    let string: String
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        let stringOffset =  itemsContainer.translate(next: .doubleWords,
                                                     dataInterpreter: DataInterpreterPreset.UInt32,
                                                     itemContentGenerator: { stringOffset in TranslationItemContent(description: "String Offset", explanation: stringOffset.hex) })
        self.stringOffset = stringOffset
        
        self.string = itemsContainer.translate(next: .rawNumber(data.count - Int(stringOffset)),
                                               dataInterpreter: { $0.utf8String ?? Log.warning("Failed to parse \(type.name). Debug me.") },
                                               itemContentGenerator: { string in TranslationItemContent(description: "Content", explanation: string) })
        
        super.init(with: type, data: data, itemsContainer: itemsContainer)
    }
}

class LCUUID: LoadCommand {
    
    let uuid: UUID
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        self.uuid = itemsContainer.translate(next: .rawNumber(16),
                                             dataInterpreter: { uuidData in LCUUID.uuid(from: [UInt8](uuidData)) },
                                             itemContentGenerator: { uuid in TranslationItemContent(description: "UUID", explanation: uuid.uuidString) })
        super.init(with: type, data: data, itemsContainer: itemsContainer)
    }
    
    static func uuid(from uuidData: [UInt8]) -> UUID {
        return UUID(uuid: (uuidData[0], uuidData[1], uuidData[2], uuidData[3], uuidData[4], uuidData[5], uuidData[6], uuidData[7],
                           uuidData[8], uuidData[9], uuidData[10], uuidData[11], uuidData[12], uuidData[13], uuidData[14], uuidData[15]))
    }
}

class LCSourceVersion: LoadCommand {
    
    let version: String
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        self.version = itemsContainer.translate(next: .quadWords,
                                                dataInterpreter: { LCSourceVersion.versionString(from: $0.UInt64) },
                                                itemContentGenerator: { version in TranslationItemContent(description: "Source Version", explanation: version) })
        
        super.init(with: type, data: data, itemsContainer: itemsContainer)
    }
    
    static func versionString(from versionValue: UInt64) -> String {
        /* A.B.C.D.E packed as a24.b10.c10.d10.e10 */
        let mask: Swift.UInt64 = 0x3ff
        let e = versionValue & mask
        let d = (versionValue >> 10) & mask
        let c = (versionValue >> 20) & mask
        let b = (versionValue >> 30) & mask
        let a = versionValue >> 40
        return String(format: "%d.%d.%d.%d.%d", a, b, c, d, e)
    }
}

class LCMain: LoadCommand {
    
    let entryOffset: UInt64
    let stackSize: UInt64
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        self.entryOffset = itemsContainer.translate(next: .quadWords,
                                                    dataInterpreter: { $0.UInt64 },
                                                    itemContentGenerator: { entryOffset in TranslationItemContent(description: "Entry Offset (relative to __TEXT)",
                                                                                                                  explanation: entryOffset.hex) })
        
        self.stackSize = itemsContainer.translate(next: .quadWords,
                                                  dataInterpreter: { $0.UInt64 },
                                                  itemContentGenerator: { stackSize in TranslationItemContent(description: "Stack Size",
                                                                                                              explanation: stackSize.hex) })
        
        super.init(with: type, data: data, itemsContainer: itemsContainer)
    }
}
