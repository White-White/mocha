//
//  Macho.swift
//  mocha
//
//  Created by white on 2021/6/16.
//

import Foundation

enum MachoType {
    case object
    case execute
    case dylib
    case unknown(UInt32)
    
    init(with value: UInt32) {
        switch value {
        case 0x1:
            self = .object
        case 0x2:
            self = .execute
        case 0x6:
            self = .dylib
        default:
            self = .unknown(value)
        }
    }
    
    var readable: String {
        switch self {
        case .object:
            return "MH_OBJECT" // : Relocatable object file
        case .execute:
            return "MH_EXECUTE" // : Demand paged executable file
        case .dylib:
            return "MH_DYLIB" // : Dynamically bound shared library
        case .unknown(let value):
            return "unknown macho file: (\(value)"
        }
    }
}

class MachoHeader: MachoComponent {
    
    let is64Bit: Bool
    let cpuType: CPUType
    let cpuSubtype: CPUSubtype
    let machoType: MachoType
    let numberOfLoadCommands: UInt32
    let sizeOfAllLoadCommand: UInt32
    let flags: UInt32
    let reserved: UInt32?
    let translationStore: TranslationStore
    
    override var componentTitle: String { "Macho Header" }
    
    override func numberOfTranslationSections() -> Int {
        return 1
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return translationStore.items.count
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        return translationStore.items[indexPath.item]
    }
    
    init(from machoDataSlice: DataSlice, is64Bit: Bool) {
        self.is64Bit = is64Bit
        
        let transStore = TranslationStore(machoDataSlice: machoDataSlice)
        
        _ =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: { $0 },
                             itemContentGenerator: { _  in TranslationItemContent(description: "File Magic", explanation: (is64Bit ? MagicType.macho64 : MagicType.macho32).readable) })
        
        let cpuType =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: { CPUType($0.UInt32) },
                             itemContentGenerator: { cpuType  in TranslationItemContent(description: "CPU Type", explanation: cpuType.name) })
        self.cpuType = cpuType
        
        self.cpuSubtype =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: { CPUSubtype($0.UInt32, cpuType: cpuType) },
                             itemContentGenerator: { cpuSubtype  in TranslationItemContent(description: "CPU Sub Type", explanation: cpuSubtype.name) })
        
        self.machoType =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: { MachoType(with: $0.UInt32) },
                             itemContentGenerator: { machoType  in TranslationItemContent(description: "Macho Type", explanation: machoType.readable) })
        
        self.numberOfLoadCommands =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: DataInterpreterPreset.UInt32,
                             itemContentGenerator: { numberOfLoadCommands  in TranslationItemContent(description: "Number of Load Commands", explanation: "\(numberOfLoadCommands)") })
        
        self.sizeOfAllLoadCommand =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: DataInterpreterPreset.UInt32,
                             itemContentGenerator: { sizeOfAllLoadCommand  in TranslationItemContent(description: "Size of all Load Commands", explanation: sizeOfAllLoadCommand.hex) })
        
        self.flags =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: DataInterpreterPreset.UInt32,
                             itemContentGenerator: { flags  in TranslationItemContent(description: "Valid Flags", explanation: MachoHeader.flagsDescriptionFrom(flags)) })
        
        if is64Bit {
            self.reserved =
            transStore.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { reserved  in TranslationItemContent(description: "Reversed", explanation: reserved.hex) })
        } else {
            self.reserved = nil
        }
        
        self.translationStore = transStore
        
        super.init(machoDataSlice)
    }
    
    private static func flagsDescriptionFrom(_ flags: UInt32) -> String {
        // this line of shit I'll never understand.. after today...
        return [
            "MH_NOUNDEFS",
            "MH_INCRLINK",
            "MH_DYLDLINK",
            "MH_BINDATLOAD",
            "MH_PREBOUND",
            "MH_SPLIT_SEGS",
            "MH_LAZY_INIT",
            "MH_TWOLEVEL",
            "MH_FORCE_FLAT",
            "MH_NOMULTIDEFS",
            "MH_NOFIXPREBINDING",
            "MH_PREBINDABLE",
            "MH_ALLMODSBOUND",
            "MH_SUBSECTIONS_VIA_SYMBOLS",
            "MH_CANONICAL",
            "MH_WEAK_DEFINES",
            "MH_BINDS_TO_WEAK",
            "MH_ALLOW_STACK_EXECUTION",
            "MH_ROOT_SAFE",
            "MH_SETUID_SAFE",
            "MH_NO_REEXPORTED_DYLIBS",
            "MH_PIE",
            "MH_DEAD_STRIPPABLE_DYLIB",
            "MH_HAS_TLV_DESCRIPTORS",
            "MH_NO_HEAP_EXECUTION",
        ].enumerated().filter { flags & (0x1 << $0.offset) != 0 }.map { $0.element }.joined(separator: "\n")
    }
}

class Macho: Equatable {
    static func == (lhs: Macho, rhs: Macho) -> Bool {
        return lhs.data == rhs.data
    }
    let data: DataSlice
    var fileSize: Int { data.count }
    let machoFileName: String
    let header: MachoHeader
    var is64Bit: Bool { header.is64Bit }
    
    private(set) var loadCommands: [LoadCommand] = []
    private(set) var sectionHeaders: [SectionHeader] = []
    private(set) var machoComponents: [MachoComponent] = []
    
    var allCStringInterpreters: [CStringInterpreter] = []
    var stringTableInterpreter: CStringInterpreter?
    var symbolTableInterpreter: ModelBasedInterpreter<SymbolTableEntry>?
    var indirectSymbolTableInterpreter: ModelBasedInterpreter<IndirectSymbolTableEntry>?
    
    let dynamicSymbolTable: LCDynamicSymbolTable? = nil //FIXME:
    
    init(with machoDataRaw: Data, machoFileName: String) {
        let machoData = DataSlice(machoDataRaw)
        self.data = machoData
        self.machoFileName = machoFileName
        
        guard let magicType = MagicType(machoData.raw) else { fatalError() }
        let is64bit = magicType == .macho64
        
        let header = MachoHeader(from: machoData.truncated(from: .zero, length: is64bit ? 32 : 28), is64Bit: is64bit)
        self.header = header
        self.machoComponents.append(header)
        
        var textSegmentVirtualStartAddress: UInt64!
        
        var nextLoadCommandStartOffset = header.componentSize
        for _ in 0..<header.numberOfLoadCommands {
            
            let loadCommandTypeRaw = machoData.truncated(from: nextLoadCommandStartOffset, length: 4).raw.UInt32
            guard let loadCommandType = LoadCommandType(rawValue: loadCommandTypeRaw) else {
                print("Unknown load command type \(loadCommandTypeRaw.hex). This must be a new one.")
                fatalError()
            }
            
            let loadCommandSize = Int(machoData.truncated(from: nextLoadCommandStartOffset + 4, length: 4).raw.UInt32)
            let loadCommandData = machoData.truncated(from: nextLoadCommandStartOffset, length: loadCommandSize)
            nextLoadCommandStartOffset += loadCommandSize
            
            let loadCommand: LoadCommand
            switch loadCommandType {
            case .iOSMinVersion, .macOSMinVersion, .tvOSMinVersion, .watchOSMinVersion:
                loadCommand = LCMinOSVersion(with: loadCommandType, data: loadCommandData)
            case .linkerOption:
                loadCommand = LCLinkerOption(with: loadCommandType, data: loadCommandData)
            case .segment, .segment64:
                let segment = LCSegment(with: loadCommandType, data: loadCommandData)
                let segmentSectionHeaders = segment.sectionHeaders
                self.sectionHeaders.append(contentsOf: segmentSectionHeaders)
                self.machoComponents.append(contentsOf: segmentSectionHeaders.compactMap({ self.machoComponent(from: $0) }))
                self.machoComponents.append(contentsOf: segmentSectionHeaders.compactMap({ self.relocationComponent(from: $0) }))
                if segment.segmentFileOff == 0 && segment.segmentSize != 0 /* first non-zero segment */ {
                    textSegmentVirtualStartAddress = segment.vmaddr
                }
                loadCommand = segment
            case .symbolTable:
                let symbolTableCommand = LCSymbolTable(with: loadCommandType, data: loadCommandData)
                let symbolTableComponent = self.symbolTableComponent(from: symbolTableCommand)
                let stringTableComponent = self.stringTableComponent(from: symbolTableCommand)
                self.symbolTableInterpreter = symbolTableComponent.interpreter as? ModelBasedInterpreter<SymbolTableEntry>
                self.stringTableInterpreter = stringTableComponent.interpreter as? CStringInterpreter
                self.machoComponents.append(contentsOf: [symbolTableComponent, stringTableComponent])
                loadCommand = symbolTableCommand
            case .dynamicSymbolTable:
                guard self.symbolTableInterpreter != nil else {
                    fatalError()
                    /* symtab_command must be present when this load command is present */
                    /* also we assume symtab_command locates before dysymtab_command */
                }
                let dynamicSymbolTableCommand = LCDynamicSymbolTable(with: loadCommandType, data: loadCommandData)
                self.machoComponents.append(self.indirectSymbolTableComponent(from: dynamicSymbolTableCommand))
                loadCommand = dynamicSymbolTableCommand
            case .idDylib, .loadDylib, .loadWeakDylib, .reexportDylib, .lazyLoadDylib, .loadUpwardDylib:
                loadCommand = LCDylib(with: loadCommandType, data: loadCommandData)
            case .rpath, .idDynamicLinker, .loadDynamicLinker, .dyldEnvironment:
                loadCommand = LCMonoString(with: loadCommandType, data: loadCommandData)
            case .uuid:
                loadCommand = LCUUID(with: loadCommandType, data: loadCommandData)
            case .sourceVersion:
                loadCommand = LCSourceVersion(with: loadCommandType, data: loadCommandData)
            case .dataInCode, .codeSignature, .functionStarts, .segmentSplitInfo, .dylibCodeSigDRs, .linkerOptimizationHint, .dyldExportsTrie, .dyldChainedFixups:
                let linkedITData = LCLinkedITData(with: loadCommandType, data: loadCommandData)
                if linkedITData.containedDataSize.isNotZero {
                    // segment command is before linkedit data sections,
                    // so the textSegmentVirtualStartAddress must not be nil, unless something goes wrong
                    self.machoComponents.append(self.machoComponent(from: linkedITData, textSegmentVirtualStartAddress: textSegmentVirtualStartAddress))
                }
                loadCommand = linkedITData
            case .main:
                loadCommand = LCMain(with: loadCommandType, data: loadCommandData)
            case .dyldInfo, .dyldInfoOnly:
                let dyldInfo = LCDyldInfo(with: loadCommandType, data: loadCommandData)
                let dyldInfoComponents = self.dyldInfoComponents(from: dyldInfo)
                self.machoComponents.append(contentsOf: dyldInfoComponents)
                loadCommand = dyldInfo
            case .encryptionInfo64,. encryptionInfo:
                loadCommand = LCEncryptionInfo(with: loadCommandType, data: loadCommandData)
            case .buildVersion:
                loadCommand = LCBuildVersion(with: loadCommandType, data: loadCommandData)
            default:
                Log.warning("Unknown load command \(loadCommandType.name). Debug me.")
                loadCommand = LoadCommand(with: loadCommandType, data: loadCommandData)
            }
            self.loadCommands.append(loadCommand)
            self.machoComponents.append(loadCommand)
        }
        
        // sort
        self.machoComponents.sort { $0.componentFileOffset < $1.componentFileOffset }
    }
}

extension Macho {
    fileprivate func relocationComponent(from sectionHeader: SectionHeader) -> MachoComponent? {
        let relocationOffset = Int(sectionHeader.fileOffsetOfRelocationEntries)
        let numberOfRelocEntries = Int(sectionHeader.numberOfRelocatioEntries)
        
        if relocationOffset != 0 && numberOfRelocEntries != 0 {
            let entriesData = data.truncated(from: relocationOffset, length: numberOfRelocEntries * RelocationEntry.modelSize(is64Bit: is64Bit))
            let interpreter = ModelBasedInterpreter<RelocationEntry>.init(entriesData, is64Bit: is64Bit, machoSearchSource: self)
            return MachoInterpreterBasedComponent.init(entriesData,
                                                       is64Bit: is64Bit,
                                                       interpreter: interpreter,
                                                       title: "Relocation Table",
                                                       subTitle: "__LINKEDIT" + "," + sectionHeader.section)
        } else {
            return nil
        }
    }
    
    fileprivate func machoComponent(from sectionHeader: SectionHeader) -> MachoComponent? {
        // zero filled section has no data from mach-o file
        guard !sectionHeader.isZerofilled else { return nil }
        
        // some section may contain zero bytes. (eg: cocoapods generated section)
        guard sectionHeader.size > 0 else { return nil }
        
        let dataSlice = data.truncated(from: Int(sectionHeader.offset), length: Int(sectionHeader.size))
        
        /* recognize section by section type */
        if sectionHeader.sectionType == .S_CSTRING_LITERALS {
            let cStringInterpreter = CStringInterpreter(dataSlice, is64Bit: is64Bit,
                                                        machoSearchSource: self,
                                                        sectionVirtualAddress: sectionHeader.addr,
                                                        demanglingCString: true)
            self.allCStringInterpreters.append(cStringInterpreter)
            return MachoInterpreterBasedComponent(dataSlice, is64Bit: is64Bit, interpreter: cStringInterpreter, title: "Section",
                                                  subTitle: sectionHeader.segment + "," + sectionHeader.section)
        }
        
        if sectionHeader.sectionType == .S_LITERAL_POINTERS {
            let literalPointerInterpreter = LiteralPointerInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
            return MachoInterpreterBasedComponent(dataSlice, is64Bit: is64Bit, interpreter: literalPointerInterpreter, title: "Section",
                                                  subTitle: sectionHeader.segment + "," + sectionHeader.section)
        }
        
        if sectionHeader.sectionType == .S_LAZY_SYMBOL_POINTERS || sectionHeader.sectionType == .S_NON_LAZY_SYMBOL_POINTERS {
            let symbolPtrInterpreter = SymbolPointerInterpreter(dataSlice, is64Bit: is64Bit,
                                                                machoSearchSource: self,
                                                                sectionType: sectionHeader.sectionType,
                                                                startIndexInIndirectSymbolTable: Int(sectionHeader.reserved1))
            return MachoInterpreterBasedComponent(dataSlice, is64Bit: is64Bit, interpreter: symbolPtrInterpreter, title: "Section",
                                                  subTitle: sectionHeader.segment + "," + sectionHeader.section)
        }
        
        if sectionHeader.sectionAttributes.hasAttribute(.S_ATTR_PURE_INSTRUCTIONS) {
            let interpreter: Interpreter
            if (sectionHeader.section == "__text") {
                interpreter = CowardInterpreter(description: "Code",
                                                explanation: "This part of the macho is machine code. Hopper.app would be a better choice to parse it.")
            } else {
                interpreter = InstructionInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
            }
            return MachoInterpreterBasedComponent(dataSlice, is64Bit: is64Bit, interpreter: interpreter, title: "Section",
                                                  subTitle: sectionHeader.segment + "," + sectionHeader.section)
        }
        
        /* recognize section by section name */
        let interpreter: Interpreter
        switch sectionHeader.segment {
        case "__TEXT":
            switch sectionHeader.section {
            case "__ustring":
                interpreter = UStringInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
            case "__swift5_reflstr":
                // https://knight.sc/reverse%20engineering/2019/07/17/swift-metadata.html
                // a great article on introducing swift metadata sections
                interpreter = CStringInterpreter(dataSlice, is64Bit: is64Bit,
                                                 machoSearchSource: self,
                                                 sectionVirtualAddress: sectionHeader.addr,
                                                 demanglingCString: false)
            default:
                interpreter = ASCIIInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
            }
        default:
            interpreter = ASCIIInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
        }
        return MachoInterpreterBasedComponent(dataSlice,
                                              is64Bit: is64Bit,
                                              interpreter: interpreter,
                                              title: "Section",
                                              subTitle: sectionHeader.segment + "," + sectionHeader.section)
    }
    
    fileprivate func machoComponent(from linkedITData: LCLinkedITData, textSegmentVirtualStartAddress: UInt64) -> MachoComponent {
        let dataSlice = data.truncated(from: Int(linkedITData.containedDataFileOffset),
                                       length: Int(linkedITData.containedDataSize))
        let interpreter: Interpreter
        switch linkedITData.type {
        case .dataInCode:
            interpreter = ModelBasedInterpreter<DataInCodeModel>(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
        case .codeSignature:
            // ref: https://opensource.apple.com/source/Security/Security-55471/sec/Security/Tool/codesign.c
            // FIXME: better parsing
            interpreter = ASCIIInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
        case .functionStarts:
            let functionStartsInterpreter = FunctionStartsInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
            functionStartsInterpreter.textSegmentVirtualStartAddress = textSegmentVirtualStartAddress
            interpreter = functionStartsInterpreter
        case .dyldExportsTrie:
            interpreter = ExportInfoInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
        default:
            print("Unknow how to parse \(self). Please contact the author.") // FIXME: LC_SEGMENT_SPLIT_INFO not parsed
            interpreter = ASCIIInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
        }
        return MachoInterpreterBasedComponent(dataSlice,
                                              is64Bit: is64Bit,
                                              interpreter: interpreter,
                                              title: linkedITData.dataName,
                                              subTitle: "__LINKEDIT")
    }
    
    fileprivate func symbolTableComponent(from symbolTableCommand: LCSymbolTable) -> MachoInterpreterBasedComponent {
        let symbolTableStartOffset = Int(symbolTableCommand.symbolTableOffset)
        let numberOfEntries = Int(symbolTableCommand.numberOfSymbolTableEntries)
        let entrySize = is64Bit ? 16 : 12
        let symbolTableData = data.truncated(from: symbolTableStartOffset, length: numberOfEntries * entrySize)
        let interpreter = ModelBasedInterpreter<SymbolTableEntry>.init(symbolTableData, is64Bit: is64Bit, machoSearchSource: self)
        return MachoInterpreterBasedComponent(symbolTableData,
                                              is64Bit: is64Bit,
                                              interpreter: interpreter,
                                              title: "Symbol Table",
                                              subTitle: "__LINKEDIT")
    }
    
    fileprivate func stringTableComponent(from symbolTableCommand: LCSymbolTable) -> MachoInterpreterBasedComponent {
        let stringTableStartOffset = Int(symbolTableCommand.stringTableOffset)
        let stringTableSize = Int(symbolTableCommand.sizeOfStringTable)
        let stringTableData = data.truncated(from: stringTableStartOffset, length: stringTableSize)
        let interpreter = CStringInterpreter(stringTableData, is64Bit: is64Bit,
                                             machoSearchSource: self,
                                             sectionVirtualAddress: 0,
                                             demanglingCString: false)
        allCStringInterpreters.append(interpreter)
        return MachoInterpreterBasedComponent(stringTableData,
                                              is64Bit: is64Bit,
                                              interpreter: interpreter,
                                              title: "String Table",
                                              subTitle: "__LINKEDIT")
    }
    
    fileprivate func indirectSymbolTableComponent(from dynamicSymbolCommand: LCDynamicSymbolTable) -> MachoInterpreterBasedComponent {
        let indirectSymbolTableStartOffset = Int(dynamicSymbolCommand.indirectsymoff)
        let indirectSymbolTableSize = Int(dynamicSymbolCommand.nindirectsyms * 4)
        let indirectSymbolTableData = data.truncated(from: indirectSymbolTableStartOffset, length: indirectSymbolTableSize)
        let interpreter = ModelBasedInterpreter<IndirectSymbolTableEntry>.init(indirectSymbolTableData, is64Bit: is64Bit, machoSearchSource: self)
        self.indirectSymbolTableInterpreter = interpreter
        return MachoInterpreterBasedComponent(indirectSymbolTableData,
                                              is64Bit: is64Bit,
                                              interpreter: interpreter,
                                              title: "Indirect Symbol Table",
                                              subTitle: "__LINKEDIT")
    }
    
    fileprivate func dyldInfoComponents(from dyldInfoCommand: LCDyldInfo) -> [MachoComponent] {
        var components: [MachoComponent] = []
        
        let rebaseInfoStart = Int(dyldInfoCommand.rebaseOffset)
        let rebaseInfoSize = Int(dyldInfoCommand.rebaseSize)
        if rebaseInfoStart.isNotZero && rebaseInfoSize.isNotZero {
            let rebaseInfoData = data.truncated(from: rebaseInfoStart, length: rebaseInfoSize)
            let interpreter = OperationCodeInterpreter<RebaseOperationCode>.init(rebaseInfoData, is64Bit: is64Bit, machoSearchSource: self)
            let rebaseInfoComponent = MachoInterpreterBasedComponent(rebaseInfoData,
                                                                     is64Bit: is64Bit,
                                                                     interpreter: interpreter,
                                                                     title: "Rebase Opcode",
                                                                     subTitle: "__LINKEDIT")
            components.append(rebaseInfoComponent)
        }
        
        
        let bindInfoStart = Int(dyldInfoCommand.bindOffset)
        let bindInfoSize = Int(dyldInfoCommand.bindSize)
        if bindInfoStart.isNotZero && bindInfoSize.isNotZero {
            let bindInfoData = data.truncated(from: bindInfoStart, length: bindInfoSize)
            let interpreter = OperationCodeInterpreter<BindOperationCode>.init(bindInfoData, is64Bit: is64Bit, machoSearchSource: self)
            let bindingInfoComponent = MachoInterpreterBasedComponent(bindInfoData,
                                                                      is64Bit: is64Bit,
                                                                      interpreter: interpreter,
                                                                      title: "Binding Opcode",
                                                                      subTitle: "__LINKEDIT")
            components.append(bindingInfoComponent)
        }
        
        let weakBindInfoStart = Int(dyldInfoCommand.weakBindOffset)
        let weakBindSize = Int(dyldInfoCommand.weakBindSize)
        if weakBindInfoStart.isNotZero && weakBindSize.isNotZero {
            let weakBindData = data.truncated(from: weakBindInfoStart, length: weakBindSize)
            let interpreter = OperationCodeInterpreter<BindOperationCode>.init(weakBindData, is64Bit: is64Bit, machoSearchSource: self)
            let weakBindingInfoComponent = MachoInterpreterBasedComponent(weakBindData,
                                                                          is64Bit: is64Bit,
                                                                          interpreter: interpreter,
                                                                          title: "Weak Binding Opcode",
                                                                          subTitle: "__LINKEDIT")
            components.append(weakBindingInfoComponent)
        }
        
        let lazyBindInfoStart = Int(dyldInfoCommand.lazyBindOffset)
        let lazyBindSize = Int(dyldInfoCommand.lazyBindSize)
        if lazyBindInfoStart.isNotZero && lazyBindSize.isNotZero {
            let lazyBindData = data.truncated(from: lazyBindInfoStart, length: lazyBindSize)
            let interpreter = OperationCodeInterpreter<BindOperationCode>.init(lazyBindData, is64Bit: is64Bit, machoSearchSource: self)
            let lazyBindingInfoComponent = MachoInterpreterBasedComponent(lazyBindData,
                                                                          is64Bit: is64Bit,
                                                                          interpreter: interpreter,
                                                                          title: "Lazy Binding Opcode",
                                                                          subTitle: "__LINKEDIT")
            components.append(lazyBindingInfoComponent)
        }
        
        let exportInfoStart = Int(dyldInfoCommand.exportOffset)
        let exportInfoSize = Int(dyldInfoCommand.exportSize)
        if exportInfoStart.isNotZero && exportInfoSize.isNotZero {
            let exportInfoData = data.truncated(from: exportInfoStart, length: exportInfoSize)
            let interpreter = ExportInfoInterpreter.init(exportInfoData, is64Bit: is64Bit, machoSearchSource: self)
            let exportInfoComponent = MachoInterpreterBasedComponent(exportInfoData,
                                                                     is64Bit: is64Bit,
                                                                     interpreter: interpreter,
                                                                     title: "Export Info",
                                                                     subTitle: "__LINKEDIT")
            components.append(exportInfoComponent)
        }
        
        return components
    }
}

// MARK: Search String Table

protocol MachoSearchSource: AnyObject {
    
    // cpu info
    var cpuType: CPUType { get }
    var cpuSubType: CPUSubtype { get }
    
    // search string
    func stringInStringTable(at offset: Int) -> String?
    func searchString(by virtualAddress: UInt64) -> String?
    
    // section name
    func sectionName(at ordinal: Int) -> String
    
    // search in symbol table
    func symbolInSymbolTable(by virtualAddress: UInt64) -> SymbolTableEntry?
    func symbolInSymbolTable(at index: Int) -> SymbolTableEntry?
    
    // search in indirect symbol table
    func entryInIndirectSymbolTable(at index: Int) -> IndirectSymbolTableEntry?
}

extension Macho: MachoSearchSource {
    
    var cpuType: CPUType { header.cpuType }
    var cpuSubType: CPUSubtype { header.cpuSubtype }
    
    func stringInStringTable(at offset: Int) -> String? {
        return self.stringTableInterpreter?.findString(at: offset)
    }
    
    func searchString(by virtualAddress: UInt64) -> String? {
        for cStringInterpreter in self.allCStringInterpreters {
            if virtualAddress >= cStringInterpreter.sectionVirtualAddress
                && virtualAddress < (cStringInterpreter.sectionVirtualAddress + UInt64(cStringInterpreter.data.count)) {
                return cStringInterpreter.findString(with: virtualAddress)
            }
        }
        return nil
    }
    
    func sectionName(at ordinal: Int) -> String {
        if ordinal > self.sectionHeaders.count {
            fatalError()
        }
        // ordinal starts from 1
        let sectionHeader = self.sectionHeaders[ordinal - 1]
        return sectionHeader.segment + "," + sectionHeader.section
    }
    
    func symbolInSymbolTable(by virtualAddress: UInt64) -> SymbolTableEntry? {
        if let symbolTableInterpreter = self.symbolTableInterpreter {
            for symbolEntry in symbolTableInterpreter.payload {
                if symbolEntry.nValue == virtualAddress {
                    return symbolEntry
                }
            }
        }
        return nil
    }
    
    func symbolInSymbolTable(at index: Int) -> SymbolTableEntry? {
        if let symbolTableInterpreter = self.symbolTableInterpreter {
            guard index < symbolTableInterpreter.payload.count else { return nil }
            return symbolTableInterpreter.payload[index]
        }
        return nil
    }
    
    func entryInIndirectSymbolTable(at index: Int) -> IndirectSymbolTableEntry? {
        if let indirectSymbolTableInterpreter = self.indirectSymbolTableInterpreter {
            return indirectSymbolTableInterpreter.payload[index]
        }
        return nil
    }
}
