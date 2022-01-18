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
        
        let transStore = TranslationStore(machoDataSlice: machoDataSlice, sectionTitle: nil)
        
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
    let loadCommands: [LoadCommand]
    var machoComponents: [MachoComponent] = []
    var stringTableInterpreter: CStringInterpreter?
    
    let dynamicSymbolTable: DynamicSymbolTable? = nil //FIXME:
    
    init(with machoData: DataSlice, machoFileName: String) {
        self.data = machoData
        self.machoFileName = machoFileName
        
        guard let magicType = MagicType(machoData.truncated(from: .zero, length: 4)) else { fatalError() }
        let is64bit = magicType == .macho64
        
        let header = MachoHeader(from: machoData.truncated(from: .zero, length: is64bit ? 32 : 28), is64Bit: is64bit)
        self.header = header
        
        let allLoadCommandData = machoData.truncated(from: header.size, length: Int(header.sizeOfAllLoadCommand))
        let loadCommands = LoadCommand.loadCommands(from: allLoadCommandData, numberOfLoadCommands: Int(header.numberOfLoadCommands))
        self.loadCommands = loadCommands
        
        // macho header as macho component
        self.machoComponents.append(header)
        
        // macho components from load commands
        self.machoComponents.append(contentsOf: loadCommands)
        
        // loop load command to collect components
        loadCommands.forEach { loadCommand in
            if let segment = loadCommand as? Segment {
                let componentsSection = segment.sectionHeaders.compactMap({
                    Macho.machoComponent(from: $0, machoData: machoData, is64Bit: header.is64Bit)
                })
                self.machoComponents.append(contentsOf: componentsSection)
                
                let componentsRelocations = segment.sectionHeaders.compactMap({
                    Macho.relocationComponen(from: $0, machoData: machoData, is64Bit: header.is64Bit)
                })
                self.machoComponents.append(contentsOf: componentsRelocations)
            }
            
            if let linkedITData = (loadCommand as? LinkedITData), linkedITData.dataSize.isNotZero {
                self.machoComponents.append(Macho.machoComponent(from: linkedITData, machoData: machoData, is64Bit: header.is64Bit))
            }
            
            if let symbolTableCommand = (loadCommand as? SymbolTable) {
                
                let symbolTableComponent = Macho.symbolTableComponent(from: symbolTableCommand,
                                                                      machoData: machoData,
                                                                      is64Bit: header.is64Bit,
                                                                      stringTableSearchingDelegate: self)
                
                let stringTableComponent = Macho.stringTableComponent(from: symbolTableCommand, machoData: machoData, is64Bit: header.is64Bit)
                
                self.stringTableInterpreter = stringTableComponent.interpreter as? CStringInterpreter
                self.machoComponents.append(contentsOf: [symbolTableComponent, stringTableComponent])
            }
            
            if let dyldInfo = loadCommand as? LCDyldInfo {
                let dyldInfoComponents = Macho.dyldInfoComponents(from: dyldInfo, machoData: machoData, is64Bit: header.is64Bit)
                self.machoComponents.append(contentsOf: dyldInfoComponents)
            }
        }
        
        // sort
        self.machoComponents.sort { $0.fileOffsetInMacho < $1.fileOffsetInMacho }
    }
}

// MARK: MachoComponent Generation

extension Macho {
    fileprivate static func relocationComponen(from sectionHeader: SectionHeader, machoData: DataSlice, is64Bit: Bool) -> MachoComponent? {
        let relocationOffset = Int(sectionHeader.fileOffsetOfRelocationEntries)
        let numberOfRelocEntries = Int(sectionHeader.numberOfRelocatioEntries)
        
        if relocationOffset != 0 && numberOfRelocEntries != 0 {
            let entriesData = machoData.truncated(from: relocationOffset, length: numberOfRelocEntries * RelocationEntry.modelSize(is64Bit: is64Bit))
            return MachoInterpreterBasedComponent.init(entriesData,
                                                       is64Bit: is64Bit,
                                                       interpreterType: LazyModelBasedInterpreter<RelocationEntry>.self,
                                                       title: "Relocation Table",
                                                       subTitle: "__LINKEDIT" + "," + sectionHeader.section)
        } else {
            return nil
        }
    }
    
    fileprivate static func machoComponent(from sectionHeader: SectionHeader, machoData: DataSlice, is64Bit: Bool) -> MachoComponent? {
        // zero filled section has no data from mach-o file
        guard !sectionHeader.isZerofilled else { return nil }
        
        // some section may contain zero bytes. (eg: cocoapods generated section)
        guard sectionHeader.size > 0 else { return nil }
        
        var interpreterType: Interpreter.Type = ASCIIInterpreter.self
        if sectionHeader.sectionType == .S_CSTRING_LITERALS {
            interpreterType = CStringInterpreter.self
        } else {
            switch sectionHeader.segment {
            case "__TEXT":
                switch sectionHeader.section {
                case "__text":
                    interpreterType = CodeInterpreter.self
                default:
                    break
                }
            case "__DATA":
                break
            default:
                break
            }
        }
        
        return MachoInterpreterBasedComponent(machoData.truncated(from: Int(sectionHeader.offset), length: Int(sectionHeader.size)),
                                              is64Bit: is64Bit,
                                              interpreterType: interpreterType,
                                              title: "Section",
                                              subTitle: sectionHeader.segment + "," + sectionHeader.section)
    }
    
    fileprivate static func machoComponent(from linkedITData: LinkedITData, machoData: DataSlice, is64Bit: Bool) -> MachoComponent {
        return MachoInterpreterBasedComponent(machoData.truncated(from: Int(linkedITData.fileOffset), length: Int(linkedITData.dataSize)),
                                              is64Bit: is64Bit,
                                              interpreterType: linkedITData.interpreterType,
                                              title: linkedITData.dataName,
                                              subTitle: "__LINKEDIT")
    }
    
    fileprivate static func symbolTableComponent(from symbolTableCommand: SymbolTable,
                                                 machoData: DataSlice,
                                                 is64Bit: Bool,
                                                 stringTableSearchingDelegate: StringTableSearchingDelegate) -> MachoInterpreterBasedComponent {
        let symbolTableStartOffset = Int(symbolTableCommand.symbolTableOffset)
        let numberOfEntries = Int(symbolTableCommand.numberOfSymbolTableEntries)
        let entrySize = is64Bit ? 16 : 12
        let symbolTableData = machoData.truncated(from: symbolTableStartOffset, length: numberOfEntries * entrySize)
        return MachoInterpreterBasedComponent(symbolTableData,
                                              is64Bit: is64Bit,
                                              interpreterType: LazyModelBasedInterpreter<SymbolTableEntry>.self,
                                              title: "Symbol Table",
                                              interpreterSettings: [.stringTableSearchingDelegate: stringTableSearchingDelegate],
                                              subTitle: "__LINKEDIT")
    }
    
    fileprivate static func stringTableComponent(from symbolTableCommand: SymbolTable, machoData: DataSlice, is64Bit: Bool) -> MachoInterpreterBasedComponent {
        let stringTableStartOffset = Int(symbolTableCommand.stringTableOffset)
        let stringTableSize = Int(symbolTableCommand.sizeOfStringTable)
        let stringTableData = machoData.truncated(from: stringTableStartOffset, length: stringTableSize)
        return MachoInterpreterBasedComponent(stringTableData,
                                              is64Bit: is64Bit,
                                              interpreterType: CStringInterpreter.self,
                                              title: "String Table",
                                              interpreterSettings: [.shouldDemangleCString: true],
                                              subTitle: "__LINKEDIT")
    }
    
    fileprivate static func dyldInfoComponents(from dyldInfoCommand: LCDyldInfo, machoData: DataSlice, is64Bit: Bool) -> [MachoComponent] {
        var components: [MachoComponent] = []
        
        let rebaseInfoStart = Int(dyldInfoCommand.rebaseOffset)
        let rebaseInfoSize = Int(dyldInfoCommand.rebaseSize)
        if rebaseInfoStart.isNotZero && rebaseInfoSize.isNotZero {
            let rebaseInfoData = machoData.truncated(from: rebaseInfoStart, length: rebaseInfoSize)
            let rebaseInfoComponent = MachoInterpreterBasedComponent(rebaseInfoData,
                                                  is64Bit: is64Bit,
                                                  interpreterType: OperationCodeInterpreter<RebaseOperationCode>.self,
                                                  title: "Rebase Opcode",
                                                  interpreterSettings: nil,
                                                  subTitle: "__LINKEDIT")
            components.append(rebaseInfoComponent)
        }
        
        
        let bindInfoStart = Int(dyldInfoCommand.bindOffset)
        let bindInfoSize = Int(dyldInfoCommand.bindSize)
        if bindInfoStart.isNotZero && bindInfoSize.isNotZero {
            let bindInfoData = machoData.truncated(from: bindInfoStart, length: bindInfoSize)
            let bindingInfoComponent = MachoInterpreterBasedComponent(bindInfoData,
                                                  is64Bit: is64Bit,
                                                  interpreterType: OperationCodeInterpreter<BindOperationCode>.self,
                                                  title: "Binding Opcode",
                                                  interpreterSettings: nil,
                                                  subTitle: "__LINKEDIT")
            components.append(bindingInfoComponent)
        }
        
        let weakBindInfoStart = Int(dyldInfoCommand.weakBindOffset)
        let weakBindSize = Int(dyldInfoCommand.weakBindSize)
        if weakBindInfoStart.isNotZero && weakBindSize.isNotZero {
            let weakBindData = machoData.truncated(from: weakBindInfoStart, length: weakBindSize)
            let weakBindingInfoComponent = MachoInterpreterBasedComponent(weakBindData,
                                                  is64Bit: is64Bit,
                                                  interpreterType: OperationCodeInterpreter<BindOperationCode>.self,
                                                  title: "Weak Binding Opcode",
                                                  interpreterSettings: nil,
                                                  subTitle: "__LINKEDIT")
            components.append(weakBindingInfoComponent)
        }
        
        let lazyBindInfoStart = Int(dyldInfoCommand.lazyBindOffset)
        let lazyBindSize = Int(dyldInfoCommand.lazyBindSize)
        if lazyBindInfoStart.isNotZero && lazyBindSize.isNotZero {
            let lazyBindData = machoData.truncated(from: lazyBindInfoStart, length: lazyBindSize)
            let lazyBindingInfoComponent = MachoInterpreterBasedComponent(lazyBindData,
                                                  is64Bit: is64Bit,
                                                  interpreterType: OperationCodeInterpreter<BindOperationCode>.self,
                                                  title: "Lazy Binding Opcode",
                                                  interpreterSettings: nil,
                                                  subTitle: "__LINKEDIT")
            components.append(lazyBindingInfoComponent)
        }
        
        let exportInfoStart = Int(dyldInfoCommand.exportOffset)
        let exportInfoSize = Int(dyldInfoCommand.exportSize)
        if exportInfoStart.isNotZero && exportInfoSize.isNotZero {
            let exportInfoData = machoData.truncated(from: exportInfoStart, length: exportInfoSize)
            let exportInfoComponent = MachoInterpreterBasedComponent(exportInfoData,
                                                                     is64Bit: is64Bit,
                                                                     interpreterType: ExportInfoInterpreter.self,
                                                                     title: "Export Info",
                                                                     interpreterSettings: nil,
                                                                     subTitle: "__LINKEDIT")
            components.append(exportInfoComponent)
        }
        
        return components
    }
}

// MARK: Search String Table

protocol StringTableSearchingDelegate: AnyObject {
    func searchStringTable(with stringTableByteIndex: Int) -> CStringInterpreter.StringTableSearched?
}

extension Macho: StringTableSearchingDelegate {
    func searchStringTable(with stringTableByteIndex: Int) -> CStringInterpreter.StringTableSearched? {
        return self.stringTableInterpreter?.findString(at: stringTableByteIndex)
    }
}
