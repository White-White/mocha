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

class MachoHeader: SmartDataContainer, TranslationStoreDataSource {

    let is64Bit: Bool
    let smartData: SmartData
    
    let cpuType: CPUType
    let cpuSubtype: CPUSubtype
    let machoType: MachoType
    let numberOfLoadCommands: UInt32
    let sizeOfAllLoadCommand: UInt32
    let flags: UInt32
    let reserved: UInt32?
    
    var primaryName: String { "Macho Header" }
    var secondaryName: String { "Macho Header" }
    
    init(from data: SmartData, is64Bit: Bool) {
        self.is64Bit = is64Bit
        self.smartData = data
        var machoHeaderDataShifter = DataShifter(data)
        _ = machoHeaderDataShifter.nextDoubleWord() // first 4-byte is magic data
        self.cpuType = CPUType(machoHeaderDataShifter.nextDoubleWord().UInt32)
        self.cpuSubtype = CPUSubtype(machoHeaderDataShifter.nextDoubleWord().UInt32, cpuType: cpuType)
        self.machoType = MachoType(with: machoHeaderDataShifter.nextDoubleWord().UInt32)
        self.numberOfLoadCommands = machoHeaderDataShifter.nextDoubleWord().UInt32
        self.sizeOfAllLoadCommand = machoHeaderDataShifter.nextDoubleWord().UInt32
        self.flags = machoHeaderDataShifter.nextDoubleWord().UInt32
        self.reserved = is64Bit ? machoHeaderDataShifter.nextDoubleWord().UInt32 : nil
    }
    
    var numberOfTranslationSections: Int {
        return 1
    }
    
    func translationSection(at index: Int) -> TransSection {
        let section = TransSection(baseIndex: smartData.startOffsetInMacho)
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

struct MergedLinkOptionsCommand: SmartDataContainer, TranslationStoreDataSource {
    
    let linkerOptions: [LCLinkerOption]
    var smartData: SmartData
    
    var primaryName: String { LoadCommandType.linkerOption.commandName + "(s)" }
    var secondaryName: String { "\(linkerOptions.count) linker options" }
    
    init?(_ linkerOptions: [LCLinkerOption]) {
        guard !linkerOptions.isEmpty else { return nil }
        self.linkerOptions = linkerOptions
        
        var firstData = linkerOptions.first!.smartData
        linkerOptions.dropFirst().forEach { firstData.merge($0.smartData) }
        smartData = firstData
    }
    
    var numberOfTranslationSections: Int {
        linkerOptions.count
    }
    
    func translationSection(at index: Int) -> TransSection {
        return linkerOptions[index].translationSection(at: 0)
    }
}

class Macho: Equatable {
    static func == (lhs: Macho, rhs: Macho) -> Bool {
        return lhs.data == rhs.data
    }
    let data: SmartData
    var fileSize: Int { data.count }
    
    /// name of the macho file
    let machoFileName: String
    let header: MachoHeader
    private(set) var loadCommands: [LoadCommand] = []
    private var linkerOptionCommands: [LCLinkerOption] = []
    lazy var mergedLinkerOptions: MergedLinkOptionsCommand? = MergedLinkOptionsCommand(linkerOptionCommands)
    private(set) var sections: [Section] = []
    private(set) var symbolTable: SymbolTable?
    private(set) var dynamicSymbolTable: DynamicSymbolTable?
    private(set) var stringTable: StringTable?
    private(set) var relocation: Relocation?
    
    init(with machoData: SmartData, machoFileName: String) {
        self.data = machoData
        self.machoFileName = machoFileName
        
        guard let magicType = MagicType(machoData.truncated(from: .zero, length: 4)) else { fatalError() }
        let is64bit = magicType == .macho64
        
        let header = MachoHeader(from: machoData.truncated(from: .zero, length: is64bit ? 32 : 28), is64Bit: is64bit)
        self.header = header
        
        self.loadCommands = (0..<header.numberOfLoadCommands).reduce([]) { loadCommands, _ in
            
            let nextLCOffset: Int
            if let lastLoadCommand = loadCommands.last {
                nextLCOffset = lastLoadCommand.startOffsetInMacho + lastLoadCommand.dataSize
            } else {
                nextLCOffset = header.dataSize
            }
            
            let loadCommandSize = machoData.truncated(from: nextLCOffset + 4, length: 4).raw.UInt32
            let loadCommandData = machoData.truncated(from: nextLCOffset, length: Int(loadCommandSize))
            let loadCommand = LoadCommand.loadCommand(with: loadCommandData)
            
            switch loadCommand.loadCommandType {
            case .segment, .segment64:
                let sectionHeaders = (loadCommand as! LCSegment).sectionHeaders
                let sectionWithNonZeroData = sectionHeaders.filter { $0.size > 0 }
                self.sections += sectionWithNonZeroData.map {Section(header: $0, data: machoData.truncated(from: Int($0.offset), length: Int($0.size))) }
            case .symbolTable:
                let symtableCommand = loadCommand as! LCSymbolTable
                let symbolTableStartOffset = Int(symtableCommand.symbolTableOffset)
                let numberOfEntries = Int(symtableCommand.numberOfSymbolTableEntries)
                let entrySize = header.is64Bit ? 16 : 12
                let symbolTableData = machoData.truncated(from: symbolTableStartOffset, length: numberOfEntries * entrySize)
                self.symbolTable = SymbolTable(symbolTableData, numberOfEntries: numberOfEntries, is64Bit: header.is64Bit)
                
                let stringTableStartOffset = Int(symtableCommand.stringTableOffset)
                let stringTableSize = Int(symtableCommand.sizeOfStringTable)
                let stringTableData = machoData.truncated(from: stringTableStartOffset, length: stringTableSize)
                self.stringTable = StringTable(stringTableData)
            default:
                break
            }
            
            return loadCommands + [loadCommand]
        }
        
        
        while self.loadCommands.last is LCLinkerOption {
            let linkerOptionCommand = self.loadCommands.removeLast() as! LCLinkerOption
            self.linkerOptionCommands.append(linkerOptionCommand)
        }
        self.linkerOptionCommands.reverse()
        
        self.sections.forEach({ section in
            let relocationOffset = Int(section.header.fileOffsetOfRelocationEntries)
            let numberOfRelocEntries = Int(section.header.numberOfRelocatioEntries)
            if relocationOffset != 0 && numberOfRelocEntries != 0 {
                let entriesData = machoData.truncated(from: relocationOffset, length: numberOfRelocEntries * RelocationEntry.length)
                if let relocation = self.relocation {
                    relocation.addEntries(entriesData)
                } else {
                    self.relocation = Relocation(entriesData)
                }
            }
        })
    }
}
