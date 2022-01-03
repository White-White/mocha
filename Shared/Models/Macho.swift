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
    
    override var primaryName: String { "Macho Header" }
    override var secondaryName: String { "Macho Header" }
    
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
    
    let dynamicSymbolTable: DynamicSymbolTable? = nil //FIXME:
    let relocation: Relocation? = nil
    
    init(with machoData: DataSlice, machoFileName: String) {
        self.data = machoData
        self.machoFileName = machoFileName
        
        guard let magicType = MagicType(machoData.truncated(from: .zero, length: 4)) else { fatalError() }
        let is64bit = magicType == .macho64
        
        // macho header
        let header = MachoHeader(from: machoData.truncated(from: .zero, length: is64bit ? 32 : 28), is64Bit: is64bit)
        self.header = header
        
        // load commands
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
        
        
        
        // relocation entries
//        var relocation: Relocation?
//        sections.forEach({ section in
//            let relocationOffset = Int(section.header.fileOffsetOfRelocationEntries)
//            let numberOfRelocEntries = Int(section.header.numberOfRelocatioEntries)
//            if relocationOffset != 0 && numberOfRelocEntries != 0 {
//                let entriesData = machoData.truncated(from: relocationOffset, length: numberOfRelocEntries * RelocationEntry.length)
//                if let relocation = relocation {
//                    relocation.addEntries(entriesData)
//                } else {
//                    relocation = Relocation(entriesData)
//                }
//            }
//        })
//        self.relocation = relocation
    }
    
    var machoComponents: [MachoComponent] {
        var components: [MachoComponent] = [header]
        components.append(contentsOf: loadCommands)
        
        loadCommands.forEach { loadCommand in
            if let segment = loadCommand as? Segment {
                let componentsSection = segment.sectionHeaders.compactMap({ machoComponent(from: $0) })
                components.append(contentsOf: componentsSection)
            }
            if let linkedITData = (loadCommand as? LinkedITData) {
                components.append(machoComponent(from: linkedITData))
            }
            if let symbolTableCommand = (loadCommand as? LCSymbolTable) {
                components.append(contentsOf: machoComponents(from: symbolTableCommand))
            }
        }
        
        return components.sorted { $0.fileOffsetInMacho < $1.fileOffsetInMacho }
    }

    func machoComponent(from sectionHeader: SectionHeader) -> MachoComponent? {
        // zero filled section has no data from mach-o file
        guard !sectionHeader.isZerofilled else { return nil }
        
        // some section may contain zero bytes. (eg: cocoapods generated section)
        guard sectionHeader.size > 0 else { return nil }
        
        var interpreterType: Interpreter.Type = AnonymousInterpreter.self
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
        
        return MachoInterpreterBasedComponent(self.data.truncated(from: Int(sectionHeader.offset), length: Int(sectionHeader.size)),
                                              is64Bit: self.header.is64Bit,
                                              interpreterType: interpreterType,
                                              primaryName: sectionHeader.section,
                                              secondaryName: "Segment: \(sectionHeader.segment)")
    }
    
    func machoComponent(from linkedITData: LinkedITData) -> MachoComponent {
        return MachoInterpreterBasedComponent(self.data.truncated(from: Int(linkedITData.fileOffset), length: Int(linkedITData.dataSize)),
                                              is64Bit: self.header.is64Bit,
                                              interpreterType: linkedITData.interpreterType,
                                              primaryName: linkedITData.dataName,
                                              secondaryName: "__LINKEDIT")
    }
    
    func machoComponents(from symbolTableCommand: LCSymbolTable) -> [MachoComponent] {
        let symbolTableStartOffset = Int(symbolTableCommand.symbolTableOffset)
        let numberOfEntries = Int(symbolTableCommand.numberOfSymbolTableEntries)
        let entrySize = self.header.is64Bit ? 16 : 12
        let symbolTableData = data.truncated(from: symbolTableStartOffset, length: numberOfEntries * entrySize)
        
        let stringTableStartOffset = Int(symbolTableCommand.stringTableOffset)
        let stringTableSize = Int(symbolTableCommand.sizeOfStringTable)
        let stringTableData = data.truncated(from: stringTableStartOffset, length: stringTableSize)
        
        let symbolTableComponent = MachoInterpreterBasedComponent(symbolTableData,
                                                                  is64Bit: self.header.is64Bit,
                                                                  interpreterType: ModelBasedInterpreter<SymbolTableEntryModel>.self,
                                                                  primaryName: "Symbol Table",
                                                                  secondaryName: "__LINKEDIT")
        
        let stringTableComponent = MachoInterpreterBasedComponent(stringTableData,
                                                                  is64Bit: self.header.is64Bit,
                                                                  interpreterType: CStringInterpreter.self,
                                                                  primaryName: "String Table",
                                                                  secondaryName: "__LINKEDIT")
        
        return [symbolTableComponent, stringTableComponent]
    }
}
