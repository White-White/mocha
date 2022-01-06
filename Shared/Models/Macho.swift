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
    
    override var title: String { "Macho Header" }
    
    init(from machoDataSlice: DataSlice, is64Bit: Bool) {
        self.is64Bit = is64Bit
        var machoHeaderDataShifter = DataShifter(machoDataSlice)
        _ = machoHeaderDataShifter.nextDoubleWord() // first 4-byte is magic data
        self.cpuType = CPUType(machoHeaderDataShifter.nextDoubleWord().UInt32)
        self.cpuSubtype = CPUSubtype(machoHeaderDataShifter.nextDoubleWord().UInt32, cpuType: cpuType)
        self.machoType = MachoType(with: machoHeaderDataShifter.nextDoubleWord().UInt32)
        self.numberOfLoadCommands = machoHeaderDataShifter.nextDoubleWord().UInt32
        self.sizeOfAllLoadCommand = machoHeaderDataShifter.nextDoubleWord().UInt32
        self.flags = machoHeaderDataShifter.nextDoubleWord().UInt32
        self.reserved = is64Bit ? machoHeaderDataShifter.nextDoubleWord().UInt32 : nil
        super.init(machoDataSlice)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = TransSection(baseIndex: machoDataSlice.startIndex)
        section.translateNextDoubleWord { Readable(description: "File Magic", explanation: (self.is64Bit ? MagicType.macho64 : MagicType.macho32).readable) }
        section.translateNextDoubleWord { Readable(description: "CPU Type", explanation: self.cpuType.name) }
        section.translateNextDoubleWord { Readable(description: "CPU Sub Type", explanation: self.cpuSubtype.name) }
        section.translateNextDoubleWord { Readable(description: "Macho Type", explanation: self.machoType.readable) }
        section.translateNextDoubleWord { Readable(description: "Number of commands", explanation: "\(self.numberOfLoadCommands)") }
        section.translateNextDoubleWord { Readable(description: "Size of all commands", explanation: "\(self.sizeOfAllLoadCommand.hex)") }
        section.translateNextDoubleWord { Readable(description: "Valid Flags", explanation: "\(self.flagsDescriptionFrom(self.flags).joined(separator: "\n"))") }
        if let reserved = reserved {
            section.translateNextDoubleWord { Readable(description: "Reversed", explanation: "\(reserved.hex)") }
        }
        return section
    }
    
    private func flagsDescriptionFrom(_ flags: UInt32) -> [String] {
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
        ].enumerated().filter { flags & (0x1 << $0.offset) != 0 }.map { $0.element }
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
        
        // generate macho header
        let header = MachoHeader(from: machoData.truncated(from: .zero, length: is64bit ? 32 : 28), is64Bit: is64bit)
        self.header = header
        
        // generate load commands
        var loadCommands: [LoadCommand] = []
        for _ in 0..<header.numberOfLoadCommands {
            let nextLCOffset: Int
            if let lastLoadCommand = loadCommands.last {
                nextLCOffset = Int(lastLoadCommand.fileOffsetInMacho + lastLoadCommand.size)
            } else {
                nextLCOffset = header.size
            }
            let loadCommandSize = machoData.truncated(from: nextLCOffset + 4, length: 4).raw.UInt32
            let loadCommandData = machoData.truncated(from: nextLCOffset, length: Int(loadCommandSize))
            loadCommands.append(LoadCommand.loadCommand(with: loadCommandData))
        }
        self.loadCommands = loadCommands
        
        // macho components from load commands
        self.machoComponents.append(contentsOf: loadCommands)
        
        // loop load command to collect components
        var stringTableInterpreter: CStringInterpreter?
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
            
            if let linkedITData = (loadCommand as? LinkedITData) {
                self.machoComponents.append(Macho.machoComponent(from: linkedITData, machoData: machoData, is64Bit: header.is64Bit))
            }
            
            if let symbolTableCommand = (loadCommand as? LCSymbolTable) {
                
                let symbolTableComponent = Macho.symbolTableComponent(from: symbolTableCommand,
                                                                      machoData: machoData,
                                                                      is64Bit: header.is64Bit,
                                                                      stringTableSearchingDelegate: self)
                
                let stringTableComponent = Macho.stringTableComponent(from: symbolTableCommand, machoData: machoData, is64Bit: header.is64Bit)
                
                self.stringTableInterpreter = stringTableComponent.interpreter as? CStringInterpreter
                self.machoComponents.append(contentsOf: [symbolTableComponent, stringTableComponent])
            }
        }
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
                                                       interpreterType: ModelBasedInterpreter<RelocationEntry>.self,
                                                       title: "Relocation Table",
                                                       primaryName: "__LINKEDIT" + "," + sectionHeader.section)
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
                                              primaryName: sectionHeader.segment + "," + sectionHeader.section)
    }
    
    fileprivate static func machoComponent(from linkedITData: LinkedITData, machoData: DataSlice, is64Bit: Bool) -> MachoComponent {
        return MachoInterpreterBasedComponent(machoData.truncated(from: Int(linkedITData.fileOffset), length: Int(linkedITData.dataSize)),
                                              is64Bit: is64Bit,
                                              interpreterType: linkedITData.interpreterType,
                                              title: linkedITData.dataName,
                                              primaryName: "__LINKEDIT")
    }
    
    fileprivate static func symbolTableComponent(from symbolTableCommand: LCSymbolTable,
                                                 machoData: DataSlice,
                                                 is64Bit: Bool,
                                                 stringTableSearchingDelegate: StringTableSearchingDelegate) -> MachoInterpreterBasedComponent {
        let symbolTableStartOffset = Int(symbolTableCommand.symbolTableOffset)
        let numberOfEntries = Int(symbolTableCommand.numberOfSymbolTableEntries)
        let entrySize = is64Bit ? 16 : 12
        let symbolTableData = machoData.truncated(from: symbolTableStartOffset, length: numberOfEntries * entrySize)
        return MachoInterpreterBasedComponent(symbolTableData,
                                              is64Bit: is64Bit,
                                              interpreterType: ModelBasedInterpreter<SymbolTableEntry>.self,
                                              title: "Symbol Table",
                                              interpreterSettings: [.stringTableSearchingDelegate: stringTableSearchingDelegate],
                                              primaryName: "__LINKEDIT")
    }
    
    fileprivate static func stringTableComponent(from symbolTableCommand: LCSymbolTable, machoData: DataSlice, is64Bit: Bool) -> MachoInterpreterBasedComponent {
        let stringTableStartOffset = Int(symbolTableCommand.stringTableOffset)
        let stringTableSize = Int(symbolTableCommand.sizeOfStringTable)
        let stringTableData = machoData.truncated(from: stringTableStartOffset, length: stringTableSize)
        return MachoInterpreterBasedComponent(stringTableData,
                                              is64Bit: is64Bit,
                                              interpreterType: CStringInterpreter.self,
                                              title: "String Table",
                                              interpreterSettings: [.shouldDemangleCString: true],
                                              primaryName: "__LINKEDIT")
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
