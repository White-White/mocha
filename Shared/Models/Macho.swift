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
    
    init(from machoData: Data, is64Bit: Bool) {
        self.is64Bit = is64Bit
        
        let headerData = machoData.subSequence(from: .zero, count: is64Bit ? 32 : 28)
        let transStore = TranslationStore(data: headerData)
        
        _ =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: { $0 },
                             itemContentGenerator: { data in TranslationItemContent(description: "File Magic", explanation: "File Magic") })
        
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
        
        super.init(headerData)
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
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    
    let machoData: Data
    var fileSize: Int { machoData.count }
    
    private var initialized = false
    let machoFileName: String
    let header: MachoHeader
    
    var is64Bit: Bool {
        header.is64Bit
    }
    
    var hexDigits: Int {
        var machoDataSize = self.fileSize
        var digitCount = 0
        while machoDataSize != 0 { digitCount += 1; machoDataSize /= 16 }
        return digitCount
    }
    
    private(set) var sectionHeaders: [SectionHeader] = []
    
    private var loadCommandComponents: [MachoComponent] = []
    private var sectionComponents: [MachoComponent] = []
    private var linkedItComponents: [MachoComponent] = []
    private(set) var machoComponents: [MachoComponent] = []
    
    typealias StringTable = CStringComponent
    typealias SymbolTable = ModelBasedLazyComponent<SymbolTableEntry>
    typealias IndirectSymbolTable = ModelBasedLazyComponent<IndirectSymbolTableEntry>
    
    var allCStringComponents: [CStringComponent] = []
    var stringTable: StringTable?
    var symbolTable: SymbolTable?
    var indirectSymbolTable: IndirectSymbolTable?
    
    let dynamicSymbolTable: LCDynamicSymbolTable? = nil //FIXME:
    
    init(with machoData: Data, machoFileName: String, header: MachoHeader) {
        self.machoData = machoData
        self.machoFileName = machoFileName
        self.header = header
    }
    
    func initialize() {
        guard !self.initialized else { return }
        
        var nextLoadCommandStartOffset = header.dataSize
        for _ in 0..<header.numberOfLoadCommands {
            
            let loadCommandTypeRaw = machoData.subSequence(from: nextLoadCommandStartOffset, count: 4).UInt32
            guard let loadCommandType = LoadCommandType(rawValue: loadCommandTypeRaw) else {
                print("Unknown load command type \(loadCommandTypeRaw.hex). This must be a new one.")
                fatalError()
            }
            
            let loadCommandSize = Int(machoData.subSequence(from: nextLoadCommandStartOffset + 4, count: 4).UInt32)
            let loadCommandData = machoData.subSequence(from: nextLoadCommandStartOffset, count: loadCommandSize)
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
                sectionComponents.append(contentsOf: segmentSectionHeaders.compactMap({ self.machoComponent(from: $0) }))
                linkedItComponents.append(contentsOf: segmentSectionHeaders.compactMap({ self.relocationComponent(from: $0) }))
                loadCommand = segment
            case .symbolTable:
                let symbolTableCommand = LCSymbolTable(with: loadCommandType, data: loadCommandData)
                let symbolTable = self.symbolTable(from: symbolTableCommand)
                let stringTable = self.stringTable(from: symbolTableCommand)
                self.symbolTable = symbolTable
                self.stringTable = stringTable
                linkedItComponents.append(contentsOf: [symbolTable, stringTable])
                loadCommand = symbolTableCommand
            case .dynamicSymbolTable:
                guard self.symbolTable != nil else {
                    fatalError()
                    /* symtab_command must be present when this load command is present */
                    /* also we assume symtab_command locates before dysymtab_command */
                }
                let dynamicSymbolTableCommand = LCDynamicSymbolTable(with: loadCommandType, data: loadCommandData)
                if let indirectSymbolTable = self.indirectSymbolTable(from: dynamicSymbolTableCommand) {
                    linkedItComponents.append(indirectSymbolTable)
                }
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
                // In tests, DataInCode section from iOS SDK CoreRepairKit has a zero content size
                if linkedITData.containedDataSize.isNotZero {
                    linkedItComponents.append(self.machoComponent(from: linkedITData))
                }
                loadCommand = linkedITData
            case .main:
                loadCommand = LCMain(with: loadCommandType, data: loadCommandData)
            case .dyldInfo, .dyldInfoOnly:
                let dyldInfo = LCDyldInfo(with: loadCommandType, data: loadCommandData)
                let dyldInfoComponents = self.dyldInfoComponents(from: dyldInfo)
                linkedItComponents.append(contentsOf: dyldInfoComponents)
                loadCommand = dyldInfo
            case .encryptionInfo64,. encryptionInfo:
                loadCommand = LCEncryptionInfo(with: loadCommandType, data: loadCommandData)
            case .buildVersion:
                loadCommand = LCBuildVersion(with: loadCommandType, data: loadCommandData)
            default:
                Log.warning("Unknown load command \(loadCommandType.name). Debug me.")
                loadCommand = LoadCommand(with: loadCommandType, data: loadCommandData)
            }
            loadCommandComponents.append(loadCommand)
        }
        
        // sort linkedItComponents
        linkedItComponents.sort { $0.fileOffset < $1.fileOffset }
        self.machoComponents = [header] + loadCommandComponents + sectionComponents + linkedItComponents
        
        self.initialized = true
    }
}

extension Macho {
    
    typealias RelocationComponent = ModelBasedLazyComponent<RelocationEntry>
    
    fileprivate func relocationComponent(from sectionHeader: SectionHeader) -> RelocationComponent? {
        let relocationOffset = Int(sectionHeader.fileOffsetOfRelocationEntries)
        let numberOfRelocEntries = Int(sectionHeader.numberOfRelocatioEntries)
        
        if relocationOffset != 0 && numberOfRelocEntries != 0 {
            let entriesData = machoData.subSequence(from: relocationOffset, count: numberOfRelocEntries * RelocationEntry.modelSize(is64Bit: is64Bit))
            return RelocationComponent(entriesData, macho: self,
                                       is64Bit: is64Bit,
                                       title: "Relocation Table",
                                       subTitle: Constants.segmentNameLINKEDIT + "," + sectionHeader.section)
        } else {
            return nil
        }
    }
    
    fileprivate func machoComponent(from sectionHeader: SectionHeader) -> MachoComponent? {
        
        let componentTitle = "Section"
        let componentSubTitle = sectionHeader.segment + "," + sectionHeader.section
        
        // recognize section by section type
        switch sectionHeader.sectionType {
        case .S_ZEROFILL, .S_THREAD_LOCAL_ZEROFILL, .S_GB_ZEROFILL:
            // ref: https://lists.llvm.org/pipermail/llvm-commits/Week-of-Mon-20151207/319108.html
            /* code snipet from llvm
             inline bool isZeroFillSection(SectionType T) {
             return (T == llvm::MachO::S_ZEROFILL ||
             T == llvm::MachO::S_THREAD_LOCAL_ZEROFILL);
             }
             */
            return MachoZeroFilledComponent(runtimeSize: Int(sectionHeader.size), title: componentTitle, subTitle: componentSubTitle)
            
        case .S_CSTRING_LITERALS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            let cStringComponent = CStringComponent(data, macho: self, is64Bit: is64Bit, title: componentTitle, subTitle: componentSubTitle, sectionVirtualAddress: sectionHeader.addr, demanglingCString: true)
            self.allCStringComponents.append(cStringComponent)
            return cStringComponent
            
        case .S_LITERAL_POINTERS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return LiteralPointerComponent(data, macho: self, is64Bit: is64Bit, title: componentTitle, subTitle: componentSubTitle)
            
        case .S_LAZY_SYMBOL_POINTERS, .S_NON_LAZY_SYMBOL_POINTERS, .S_LAZY_DYLIB_SYMBOL_POINTERS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return SymbolPointerComponent(data, macho: self, is64Bit: is64Bit, title: componentTitle, subTitle: componentSubTitle,
                                          sectionType: sectionHeader.sectionType, startIndexInIndirectSymbolTable: Int(sectionHeader.reserved1))
            
        default:
            break
        }
        
        // recognize section by section attributes
        if sectionHeader.sectionAttributes.hasAttribute(.S_ATTR_PURE_INSTRUCTIONS) {
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            if (sectionHeader.section == Constants.sectionNameTEXT) {
                return MachoUnknownCodeComponent(data, title: componentTitle, subTitle: componentSubTitle)
            } else {
                return InstructionComponent(data, macho:self, is64Bit: is64Bit, title: componentTitle, subTitle: componentSubTitle)
            }
        }
        
        // recognize section by section name
        let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
        switch sectionHeader.segment {
        case Constants.sectionNameTEXT:
            switch sectionHeader.section {
            case Constants.sectionNameUString:
                return UStringComponent(data, macho:self, is64Bit: is64Bit, title: componentTitle, subTitle: componentSubTitle)
            case "__swift5_reflstr":
                // https://knight.sc/reverse%20engineering/2019/07/17/swift-metadata.html
                // a great article on introducing swift metadata sections
                return CStringComponent(data, macho:self, is64Bit: is64Bit, title: componentTitle, subTitle: componentSubTitle,
                                        sectionVirtualAddress: sectionHeader.addr, demanglingCString: false)
            default:
                return ASCIIComponent(data, macho:self, is64Bit: is64Bit, title: componentTitle, subTitle: componentSubTitle)
            }
        default:
            return ASCIIComponent(data, macho:self, is64Bit: is64Bit, title: componentTitle, subTitle: componentSubTitle)
        }
    }
    
    fileprivate func machoComponent(from linkedITData: LCLinkedITData) -> MachoComponent {
        let data = machoData.subSequence(from: Int(linkedITData.containedDataFileOffset), count: Int(linkedITData.containedDataSize))
        switch linkedITData.type {
        case .dataInCode:
            return ModelBasedLazyComponent<DataInCodeModel>(data, macho: self, is64Bit: is64Bit, title: linkedITData.dataName, subTitle: Constants.segmentNameLINKEDIT)
        case .codeSignature:
            // ref: https://opensource.apple.com/source/Security/Security-55471/sec/Security/Tool/codesign.c
            // FIXME: better parsing
            return ASCIIComponent(data, macho: self, is64Bit: is64Bit, title: linkedITData.dataName, subTitle: Constants.segmentNameLINKEDIT)
        case .functionStarts:
            return FunctionStartsComponent(data, macho: self, is64Bit: is64Bit, title: linkedITData.dataName, subTitle: Constants.segmentNameLINKEDIT)
        case .dyldExportsTrie:
            return ExportInfoComponent(data, macho: self, is64Bit: is64Bit, title: linkedITData.dataName, subTitle: Constants.segmentNameLINKEDIT)
        default:
            print("Unknow how to parse \(self). Please contact the author.") // FIXME: LC_SEGMENT_SPLIT_INFO not parsed
            return ASCIIComponent(data, macho: self, is64Bit: is64Bit, title: linkedITData.dataName, subTitle: Constants.segmentNameLINKEDIT)
        }
    }
    
    fileprivate func symbolTable(from symbolTableCommand: LCSymbolTable) -> SymbolTable {
        let symbolTableStartOffset = Int(symbolTableCommand.symbolTableOffset)
        let numberOfEntries = Int(symbolTableCommand.numberOfSymbolTableEntries)
        let entrySize = is64Bit ? 16 : 12
        let symbolTableData = machoData.subSequence(from: symbolTableStartOffset, count: numberOfEntries * entrySize)
        return SymbolTable(symbolTableData,
                           macho: self,
                           is64Bit: is64Bit,
                           title: "Symbol Table",
                           subTitle: Constants.segmentNameLINKEDIT)
    }
    
    fileprivate func stringTable(from symbolTableCommand: LCSymbolTable) -> StringTable {
        let stringTableStartOffset = Int(symbolTableCommand.stringTableOffset)
        let stringTableSize = Int(symbolTableCommand.sizeOfStringTable)
        let stringTableData = machoData.subSequence(from: stringTableStartOffset, count: stringTableSize)
        let stringTable = StringTable(stringTableData,
                                      macho: self,
                                      is64Bit: is64Bit,
                                      title: "String Table",
                                      subTitle: Constants.segmentNameLINKEDIT,
                                      sectionVirtualAddress: 0,
                                      demanglingCString: false)
        allCStringComponents.append(stringTable)
        return stringTable
    }
    
    fileprivate func indirectSymbolTable(from dynamicSymbolCommand: LCDynamicSymbolTable) -> IndirectSymbolTable? {
        let indirectSymbolTableStartOffset = Int(dynamicSymbolCommand.indirectsymoff)
        let indirectSymbolTableSize = Int(dynamicSymbolCommand.nindirectsyms * 4)
        if indirectSymbolTableSize == .zero { return nil }
        let indirectSymbolTableData = machoData.subSequence(from: indirectSymbolTableStartOffset, count: indirectSymbolTableSize)
        return IndirectSymbolTable(indirectSymbolTableData,
                                   macho:self,
                                   is64Bit: is64Bit,
                                   title: "Indirect Symbol Table",
                                   subTitle: Constants.segmentNameLINKEDIT)
    }
    
    fileprivate func dyldInfoComponents(from dyldInfoCommand: LCDyldInfo) -> [MachoComponent] {
        var components: [MachoComponent] = []
        
        let rebaseInfoStart = Int(dyldInfoCommand.rebaseOffset)
        let rebaseInfoSize = Int(dyldInfoCommand.rebaseSize)
        if rebaseInfoStart.isNotZero && rebaseInfoSize.isNotZero {
            let rebaseInfoData = machoData.subSequence(from: rebaseInfoStart, count: rebaseInfoSize)
            let rebaseInfoComponent = OperationCodeComponent<RebaseOperationCode>(rebaseInfoData,
                                                                                  macho:self,
                                                                                  is64Bit: is64Bit,
                                                                                  title: "Rebase Opcode",
                                                                                  subTitle: Constants.segmentNameLINKEDIT)
            components.append(rebaseInfoComponent)
        }
        
        
        let bindInfoStart = Int(dyldInfoCommand.bindOffset)
        let bindInfoSize = Int(dyldInfoCommand.bindSize)
        if bindInfoStart.isNotZero && bindInfoSize.isNotZero {
            let bindInfoData = machoData.subSequence(from: bindInfoStart, count: bindInfoSize)
            let bindingInfoComponent = OperationCodeComponent<BindOperationCode>(bindInfoData,
                                                                                 macho:self,
                                                                                 is64Bit: is64Bit,
                                                                                 title: "Binding Opcode",
                                                                                 subTitle: Constants.segmentNameLINKEDIT)
            components.append(bindingInfoComponent)
        }
        
        let weakBindInfoStart = Int(dyldInfoCommand.weakBindOffset)
        let weakBindSize = Int(dyldInfoCommand.weakBindSize)
        if weakBindInfoStart.isNotZero && weakBindSize.isNotZero {
            let weakBindData = machoData.subSequence(from: weakBindInfoStart, count: weakBindSize)
            let weakBindingInfoComponent = OperationCodeComponent<BindOperationCode>(weakBindData,
                                                                                     macho:self,
                                                                                     is64Bit: is64Bit,
                                                                                     title: "Weak Binding Opcode",
                                                                                     subTitle: Constants.segmentNameLINKEDIT)
            components.append(weakBindingInfoComponent)
        }
        
        let lazyBindInfoStart = Int(dyldInfoCommand.lazyBindOffset)
        let lazyBindSize = Int(dyldInfoCommand.lazyBindSize)
        if lazyBindInfoStart.isNotZero && lazyBindSize.isNotZero {
            let lazyBindData = machoData.subSequence(from: lazyBindInfoStart, count: lazyBindSize)
            let lazyBindingInfoComponent = OperationCodeComponent<BindOperationCode>(lazyBindData,
                                                                                     macho:self,
                                                                                     is64Bit: is64Bit,
                                                                                     title: "Lazy Binding Opcode",
                                                                                     subTitle: Constants.segmentNameLINKEDIT)
            components.append(lazyBindingInfoComponent)
        }
        
        let exportInfoStart = Int(dyldInfoCommand.exportOffset)
        let exportInfoSize = Int(dyldInfoCommand.exportSize)
        if exportInfoStart.isNotZero && exportInfoSize.isNotZero {
            let exportInfoData = machoData.subSequence(from: exportInfoStart, count: exportInfoSize)
            let exportInfoComponent = ExportInfoComponent(exportInfoData,
                                                          macho:self,
                                                          is64Bit: is64Bit,
                                                          title: "Export Info",
                                                          subTitle: Constants.segmentNameLINKEDIT)
            components.append(exportInfoComponent)
        }
        
        return components
    }
}

extension Macho {
    
    var cpuType: CPUType { header.cpuType }
    var cpuSubType: CPUSubtype { header.cpuSubtype }
    
    func stringInStringTable(at offset: Int) -> String? {
        return self.stringTable?.findString(at: offset)
    }
    
    func searchString(by virtualAddress: UInt64) -> String? {
        for cStringComponent in self.allCStringComponents {
            if virtualAddress >= cStringComponent.sectionVirtualAddress
                && virtualAddress < (cStringComponent.sectionVirtualAddress + UInt64(cStringComponent.data.count)) {
                return cStringComponent.findString(with: virtualAddress)
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
        if let symbolTable = self.symbolTable {
            return symbolTable.payload.first { $0.nValue == virtualAddress && $0.symbolType == .section }
        }
        return nil
    }
    
    func symbolInSymbolTable(at index: Int) -> SymbolTableEntry? {
        if let symbolTable = self.symbolTable {
            guard index < symbolTable.payload.count else { return nil }
            return symbolTable.payload[index]
        }
        return nil
    }
    
    func entryInIndirectSymbolTable(at index: Int) -> IndirectSymbolTableEntry? {
        if let indirectSymbolTable = self.indirectSymbolTable {
            return indirectSymbolTable.payload[index]
        }
        return nil
    }
    
    func segmentCommand(withName segmentName: String) -> LCSegment? {
        return (self.loadCommandComponents.filter { ($0 as? LCSegment)?.segmentName == segmentName }).first as? LCSegment
    }
}
