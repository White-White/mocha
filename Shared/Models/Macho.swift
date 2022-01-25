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
            return "MH_OBJECT: Relocatable object file"
        case .execute:
            return "MH_EXECUTE: Demand paged executable file"
        case .dylib:
            return "MH_DYLIB: Dynamically bound shared library"
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
    
    override var numberOfTranslationItems: Int {
        return translationStore.items.count
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        return translationStore.items[index]
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
                             itemContentGenerator: { numberOfLoadCommands  in TranslationItemContent(description: "Number of commands", explanation: "\(numberOfLoadCommands)") })
        
        self.sizeOfAllLoadCommand =
        transStore.translate(next: .doubleWords,
                             dataInterpreter: DataInterpreterPreset.UInt32,
                             itemContentGenerator: { sizeOfAllLoadCommand  in TranslationItemContent(description: "Size of all commands", explanation: "\(sizeOfAllLoadCommand)") })
        
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
    
    /// name of the macho file
    let machoFileName: String
    let header: MachoHeader
    var is64Bit: Bool { header.is64Bit }
    let loadCommands: [LoadCommand]
    let sectionHeaders: [SectionHeader]
    var machoComponents: [MachoComponent] = []
    
    var allCStringInterpreters: [CStringInterpreter] = []
    var stringTableInterpreter: CStringInterpreter?
    var symbolTableInterpreter: ModelBasedInterpreter<SymbolTableEntry>?
    
    let dynamicSymbolTable: LCDynamicSymbolTable? = nil //FIXME:
    
    init(with machoData: DataSlice, machoFileName: String) {
        self.data = machoData
        self.machoFileName = machoFileName
        
        guard let magicType = MagicType(machoData.truncated(from: .zero, length: 4)) else { fatalError() }
        let is64bit = magicType == .macho64
        
        let header = MachoHeader(from: machoData.truncated(from: .zero, length: is64bit ? 32 : 28), is64Bit: is64bit)
        self.header = header
        
        let allLoadCommandData = data.truncated(from: header.size, length: Int(header.sizeOfAllLoadCommand))
        let loadCommands = LoadCommand.loadCommands(from: allLoadCommandData, numberOfLoadCommands: Int(header.numberOfLoadCommands))
        self.loadCommands = loadCommands
        
        var baseRelativeVirtualAddress: UInt64 = 0
        var sectionHeaders: [SectionHeader] = []
        loadCommands.forEach { loadCommand in
            if let segment = loadCommand as? LCSegment {
                sectionHeaders.append(contentsOf: segment.sectionHeaders)
                if segment.segmentFileOff == 0 && segment.segmentSize != 0 {
                    baseRelativeVirtualAddress = segment.vmaddr
                }
            }
        }
        self.sectionHeaders = sectionHeaders
        
        // macho header as macho component
        self.machoComponents.append(header)
        
        // macho components from load commands
        self.machoComponents.append(contentsOf: loadCommands)
        
        // macho components for sections
        let sectionMachoComponents: [MachoComponent] = sectionHeaders.compactMap({ self.machoComponent(from: $0) })
        self.machoComponents.append(contentsOf: sectionMachoComponents)
        
        // macho components for relocation entries
        let relocationMachoComponents: [MachoComponent] = sectionHeaders.compactMap({ self.relocationComponent(from: $0) })
        self.machoComponents.append(contentsOf: relocationMachoComponents)
        
        // loop load command to collect components
        loadCommands.forEach { loadCommand in
            
            if let linkedITData = (loadCommand as? LCLinkedITData), linkedITData.dataSize.isNotZero {
                self.machoComponents.append(self.machoComponent(from: linkedITData, functionStartBaseVirtualAddress: baseRelativeVirtualAddress))
            }
            
            if let symbolTableCommand = (loadCommand as? LCSymbolTable) {
                
                let symbolTableComponent = self.symbolTableComponent(from: symbolTableCommand)
                
                let stringTableComponent = self.stringTableComponent(from: symbolTableCommand)
                
                self.symbolTableInterpreter = symbolTableComponent.interpreter as? ModelBasedInterpreter<SymbolTableEntry>
                self.stringTableInterpreter = stringTableComponent.interpreter as? CStringInterpreter
                
                self.machoComponents.append(contentsOf: [symbolTableComponent, stringTableComponent])
            }
            
            if let dyldInfo = loadCommand as? LCDyldInfo {
                let dyldInfoComponents = self.dyldInfoComponents(from: dyldInfo)
                self.machoComponents.append(contentsOf: dyldInfoComponents)
            }
        }
        
        // sort
        self.machoComponents.sort { $0.fileOffsetInMacho < $1.fileOffsetInMacho }
    }
}

// MARK: MachoComponent Generation

extension Macho {
    fileprivate func relocationComponent(from sectionHeader: SectionHeader) -> MachoComponent? {
        let relocationOffset = Int(sectionHeader.fileOffsetOfRelocationEntries)
        let numberOfRelocEntries = Int(sectionHeader.numberOfRelocatioEntries)
        
        if relocationOffset != 0 && numberOfRelocEntries != 0 {
            let entriesData = data.truncated(from: relocationOffset, length: numberOfRelocEntries * RelocationEntry.modelSize(is64Bit: is64Bit))
            let interpreter = LazyModelBasedInterpreter<RelocationEntry>.init(entriesData, is64Bit: is64Bit, machoSearchSource: self)
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
        let interpreter: Interpreter
        
        switch sectionHeader.sectionType {
        case .S_CSTRING_LITERALS:
            let cStringInterpreter = CStringInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
            cStringInterpreter.componentStartVMAddr = sectionHeader.addr
            cStringInterpreter.demanglingCString = true
            self.allCStringInterpreters.append(cStringInterpreter)
            interpreter = cStringInterpreter
        case .S_LITERAL_POINTERS:
            interpreter = LiteralPointerInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
        default:
            switch sectionHeader.segment {
            case "__TEXT":
                switch sectionHeader.section {
                case "__text":
                    interpreter = CodeInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
                default:
                    interpreter = ASCIIInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
                }
//            case "__DATA":
//                break
            default:
                interpreter = ASCIIInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
            }
        }
        
        return MachoInterpreterBasedComponent(dataSlice,
                                              is64Bit: is64Bit,
                                              interpreter: interpreter,
                                              title: "Section",
                                              subTitle: sectionHeader.segment + "," + sectionHeader.section)
    }
    
    fileprivate func machoComponent(from linkedITData: LCLinkedITData, functionStartBaseVirtualAddress: UInt64) -> MachoComponent {
        let dataSlice = data.truncated(from: Int(linkedITData.fileOffset), length: Int(linkedITData.dataSize))
        let interpreter: Interpreter
        switch linkedITData.type {
        case .dataInCode:
            interpreter = LazyModelBasedInterpreter<DataInCodeModel>(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
        case .codeSignature:
            interpreter = CodeSignatureInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
        case .functionStarts:
            let functionStartsInterpreter = FunctionStartsInterpreter(dataSlice, is64Bit: is64Bit, machoSearchSource: self)
            functionStartsInterpreter.functionStartBaseVirtualAddress = functionStartBaseVirtualAddress
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
        let interpreter = CStringInterpreter(stringTableData, is64Bit: is64Bit, machoSearchSource: self)
        allCStringInterpreters.append(interpreter)
        
        return MachoInterpreterBasedComponent(stringTableData,
                                              is64Bit: is64Bit,
                                              interpreter: interpreter,
                                              title: "String Table",
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
    
    func stringInStringTable(at offset: Int) -> String?
    
    func searchString(by relativeVirtualAddress: UInt64) -> String?
    
    func sectionName(at ordinal: Int) -> String
    
    func searchSymbolTable(withRelativeVirtualAddress relativeVirtualAddress: UInt64) -> SymbolTableEntry?
}

extension Macho: MachoSearchSource {
    
    func stringInStringTable(at offset: Int) -> String? {
        return self.stringTableInterpreter?.findString(at: offset)
    }
    
    func searchString(by relativeVirtualAddress: UInt64) -> String? {
        for cStringInterpreter in self.allCStringInterpreters {
            if relativeVirtualAddress >= cStringInterpreter.componentStartVMAddr
                && relativeVirtualAddress < (cStringInterpreter.componentStartVMAddr + UInt64(cStringInterpreter.data.count)) {
                return cStringInterpreter.findString(with: relativeVirtualAddress)
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
    
    func searchSymbolTable(withRelativeVirtualAddress relativeVirtualAddress: UInt64) -> SymbolTableEntry? {
        return self.symbolTableInterpreter?.searchSymbol(withRelativeVirtualAddress: relativeVirtualAddress)
    }
}
