//
//  LoadCommand.swift
//  mocha
//
//  Created by white on 2021/6/17.
//

import Foundation

//ref: <mach-o/loader.h>
enum LoadCommandType: Equatable {
    case segment
    case segment64
    case symbolTable
    case dynamicSymbolTable
    case iOSMinVersion
    case macOSMinVersion
    case tvOSMinVersion
    case watchOSMinVersion
    case linkerOption
    case unknown(UInt32)
    
    var commandName: String {
        switch self {
        case .segment:
            return "LC_SEGMENT"
        case .segment64:
            return "LC_SEGMENT_64"
        case .iOSMinVersion:
            return "LC_VERSION_MIN_IPHONEOS"
        case .macOSMinVersion:
            return "LC_VERSION_MIN_MACOSX"
        case .tvOSMinVersion:
            return "LC_VERSION_MIN_TVOS"
        case .watchOSMinVersion:
            return "LC_VERSION_MIN_WATCHOS"
        case .symbolTable:
            return "LC_SYMTAB"
        case .dynamicSymbolTable:
            return "LC_DYSYMTAB"
        case .linkerOption:
            return "LC_LINKER_OPTION"
        case .unknown(let rawValue):
            return "unknown \(rawValue.hex)"
        }
    }
    
    init(_ rawValue: UInt32) {
        switch rawValue {
        case 0x01:
            self = .segment
        case 0x19:
            self = .segment64
        case 0x2:
            self = .symbolTable
        case 0xb:
            self = .dynamicSymbolTable
        case 0x25:
            self = .iOSMinVersion
        case 0x24:
            self = .macOSMinVersion
        case 0x2f:
            self = .tvOSMinVersion
        case 0x30:
            self = .watchOSMinVersion
        case 0x2d:
            self = .linkerOption
        default:
            self = .unknown(rawValue)
        }
    }
}

class LoadCommand: Identifiable, Equatable, BinaryTranslationStoreGenerator {
    static func == (lhs: LoadCommand, rhs: LoadCommand) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    let loadCommandType: LoadCommandType
    
    let data: SmartData
    var loadCommandSize: Int { data.count }
    let offsetInMacho: Int
    var translationDividerName: String? { nil }
    
    init(with loadCommandData: SmartData, loadCommandType: LoadCommandType, offsetInMacho: Int) {
        self.data = loadCommandData
        self.offsetInMacho = offsetInMacho
        self.loadCommandType = loadCommandType
    }
    
    static func loadCommand(with loadCommandData: SmartData, offsetInMacho: Int) -> LoadCommand {
        let loadCommandType = LoadCommandType(loadCommandData.select(from: 0, length: 4).realData.UInt32)
        switch loadCommandType {
        case .iOSMinVersion, .macOSMinVersion, .tvOSMinVersion, .watchOSMinVersion:
            return LCMinOSVersion(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
        case .linkerOption:
            return LCLinkerOption(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
        case .segment, .segment64:
            return LCSegment(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
        case .symbolTable:
            return LCSymbolTable(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
        case .dynamicSymbolTable:
            return LCDynamicSymbolTable(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
        case .unknown(_):
            return LoadCommand(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
        }
    }
    
    func binaryTranslationStore() -> BinaryTranslationStore {
        var store = BinaryTranslationStore(data: data, baseDataOffset: offsetInMacho)
        store.translateNextDoubleWord { Readable(description: "Load Command Type", explanation: "\(self.loadCommandType.commandName)", dividerName: self.translationDividerName) }
        store.translateNextDoubleWord { Readable(description: "Size", explanation: self.loadCommandSize.hex) }
        return store
    }
}

//MARK: Load command real types

class LCMinOSVersion: LoadCommand {
    
    private let osVersion: String
    private let sdkVersion: String
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType, offsetInMacho: Int) {
        let osVersionConstraint = loadCommandData.select(from: 8, length: 4).realData.UInt32
        let sdkVersionConstraint = loadCommandData.select(from: 12, length: 4).realData.UInt32
        self.osVersion = String(format: "%d.%d.%d", osVersionConstraint >> 16, (osVersionConstraint >> 8) & 0xff, osVersionConstraint & 0xff)
        self.sdkVersion = String(format: "%d.%d.%d", sdkVersionConstraint >> 16, (sdkVersionConstraint >> 8) & 0xff, sdkVersionConstraint & 0xff)
        super.init(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
    }
    
    override func binaryTranslationStore() -> BinaryTranslationStore {
        var translation = super.binaryTranslationStore()
        translation.translateNextDoubleWord { Readable(description: "\(self.osName), min required version:", explanation: "\(self.osVersion)") }
        translation.translateNextDoubleWord { Readable(description: "min required sdk version:", explanation: "\(self.sdkVersion)") }
        return translation
    }
    
    var osName: String {
        switch self.loadCommandType {
        case .iOSMinVersion:
            return "iOS"
        case .macOSMinVersion:
            return "macOS"
        case .tvOSMinVersion:
            return "tvOS"
        case .watchOSMinVersion:
            return "watchOS"
        default:
            fatalError()
        }
    }
}

class LCLinkerOption: LoadCommand {
    
    let numberOfOptions: Int
    let options: [String]
    override var translationDividerName: String? { "Linker Option" }
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType, offsetInMacho: Int) {
        self.numberOfOptions = Int(loadCommandData.select(from: 8, length: 4).realData.UInt32)
        self.options = loadCommandData.select(from: 12).realData.split(separator: 0x00).map { String(data: $0, encoding: .utf8)! }
        super.init(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
    }
    
    override func binaryTranslationStore() -> BinaryTranslationStore {
        var store = super.binaryTranslationStore()
        store.translateNextDoubleWord { Readable(description: "Number of options", explanation: "\(self.numberOfOptions)") }
        store.translateNext(self.loadCommandSize - 12) { Readable(description: "Content", explanation: "\(self.options.joined(separator: " "))") }
        return store
    }
}

class LCSegment: LoadCommand {
    
    let segmentName: String
    let vmaddr: UInt64
    let vmsize: UInt64
    let fileoff: UInt64
    let size: UInt64
    let maxprot: UInt32
    let initprot: UInt32
    let numberOfSections: UInt32
    let flags: Data
    let sectionHeaders: [SectionHeader]
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType, offsetInMacho: Int) {
        
        //        struct segment_command { /* for 32-bit architectures */
        //            uint32_t    cmd;        /* LC_SEGMENT */
        //            uint32_t    cmdsize;    /* includes sizeof section structs */
        //            char        segname[16];    /* segment name */
        //            uint32_t    vmaddr;        /* memory address of this segment */
        //            uint32_t    vmsize;        /* memory size of this segment */
        //            uint32_t    fileoff;    /* file offset of this segment */
        //            uint32_t    filesize;    /* amount to map from the file */
        //            vm_prot_t    maxprot;    /* maximum VM protection */
        //            vm_prot_t    initprot;    /* initial VM protection */
        //            uint32_t    nsects;        /* number of sections in segment */
        //            uint32_t    flags;        /* flags */
        //        };
        //
        //        struct segment_command_64 { /* for 64-bit architectures */
        //            uint32_t    cmd;        /* LC_SEGMENT_64 */
        //            uint32_t    cmdsize;    /* includes sizeof section_64 structs */
        //            char        segname[16];    /* segment name */
        //            uint64_t    vmaddr;        /* memory address of this segment */
        //            uint64_t    vmsize;        /* memory size of this segment */
        //            uint64_t    fileoff;    /* file offset of this segment */
        //            uint64_t    filesize;    /* amount to map from the file */
        //            vm_prot_t    maxprot;    /* maximum VM protection */
        //            vm_prot_t    initprot;    /* initial VM protection */
        //            uint32_t    nsects;        /* number of sections in segment */
        //            uint32_t    flags;        /* flags */
        //        };
        
        let is64BitSegment = loadCommandType == LoadCommandType.segment64
        var dataShifter = DataShifter(loadCommandData)
        dataShifter.ignore(8) // skip basic data
        
        guard let segmentName = dataShifter.shift(16).utf8String else { fatalError() /* Unlikely */ }
        self.segmentName = segmentName.spaceRemoved
        self.vmaddr = (is64BitSegment ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.vmsize = (is64BitSegment ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.fileoff = (is64BitSegment ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.size = (is64BitSegment ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.maxprot = dataShifter.nextDoubleWord().UInt32
        self.initprot = dataShifter.nextDoubleWord().UInt32
        self.numberOfSections = dataShifter.nextDoubleWord().UInt32
        self.flags = dataShifter.nextDoubleWord()
        
        self.sectionHeaders = (0..<numberOfSections).reduce([]) { sectionHeaders, _ in
            // section header data length for 32-bit is 68, and 64-bit 80
            let sectionHeaderLength = is64BitSegment ? 80 : 68
            let sectionHeaderData = loadCommandData.select(from: dataShifter.shifted, length: sectionHeaderLength)
            let sectionHeader = SectionHeader(is64Bit: is64BitSegment, data: sectionHeaderData, offsetInMacho: offsetInMacho + dataShifter.shifted)
            dataShifter.ignore(sectionHeaderLength)
            return sectionHeaders + [sectionHeader]
        }
        super.init(with: loadCommandData, loadCommandType: loadCommandType, offsetInMacho: offsetInMacho)
    }
    
    override func binaryTranslationStore() -> BinaryTranslationStore {
        let is64BitSegment = self.loadCommandType == LoadCommandType.segment64
        var store = super.binaryTranslationStore()
        store.translateNext(16) { Readable(description: "Segment Name: ", explanation: "\(self.segmentName)") }
        store.translateNext(is64BitSegment ? 8 : 4) { Readable(description: "vmaddr: ", explanation: "\(self.vmaddr.hex)") } //FIXME: add explanation
        store.translateNext(is64BitSegment ? 8 : 4) { Readable(description: "vmsize: ", explanation: "\(self.vmsize.hex)") } //FIXME: add explanation
        store.translateNext(is64BitSegment ? 8 : 4) { Readable(description: "file offset of this segment: ", explanation: "\(self.fileoff.hex)") } //FIXME: add explanation
        store.translateNext(is64BitSegment ? 8 : 4) { Readable(description: "amount to map from the file: ", explanation: "\(self.size.hex)") } //FIXME: add explanation
        store.translateNextDoubleWord { Readable(description: "maxprot: ", explanation: "\(self.maxprot)") } //FIXME: add explanation
        store.translateNextDoubleWord { Readable(description: "initprot: ", explanation: "\(self.initprot)") } //FIXME: add explanation
        store.translateNextDoubleWord { Readable(description: "numberOfSections: ", explanation: "\(self.numberOfSections)") } //FIXME: add explanation
        store.translateNextDoubleWord { Readable(description: "Flags", explanation: nil) } //FIXME: add explanation
        sectionHeaders.forEach { $0.addTranslations(to: &store) }
        return store
    }
}
