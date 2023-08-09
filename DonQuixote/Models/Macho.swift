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
            return "Relocatable object file (MH_OBJECT)" // : Relocatable object file
        case .execute:
            return "Demand paged executable file (MH_EXECUTE)" // : Demand paged executable file
        case .dylib:
            return "Dynamically bound shared library (MH_DYLIB)" // : Dynamically bound shared library
        case .unknown(let value):
            return "unknown macho file: (\(value)"
        }
    }
}

class MachoHeader: MachoBaseElement {
    
    let magicData: Data
    let is64Bit: Bool
    let cpuType: CPUType
    let cpuSubtype: CPUSubtype
    let machoType: MachoType
    let numberOfLoadCommands: UInt32
    let sizeOfAllLoadCommand: UInt32
    let flags: UInt32
    let reserved: UInt32?
    
    init(from machoData: Data, is64Bit: Bool) {
        self.is64Bit = is64Bit
        let headerData = machoData.subSequence(from: .zero, count: is64Bit ? 32 : 28)
        var dataShifter = DataShifter(headerData)
        self.magicData = dataShifter.shift(.doubleWords)
        self.cpuType = CPUType(dataShifter.shiftUInt32())
        self.cpuSubtype = CPUSubtype(dataShifter.shiftUInt32(), cpuType: self.cpuType)
        self.machoType = MachoType(with: dataShifter.shiftUInt32())
        self.numberOfLoadCommands = dataShifter.shiftUInt32()
        self.sizeOfAllLoadCommand = dataShifter.shiftUInt32()
        self.flags = dataShifter.shiftUInt32()
        self.reserved = is64Bit ? dataShifter.shiftUInt32() : nil
        super.init(headerData, title: "Mach Header", subTitle: nil)
    }
    
    override func loadTranslations() async {
        var translations: [Translation] = []
        translations.append(Translation(definition: "Magic", humanReadable: String.init(format: "%0X%0X%0X%0X", magicData[0], magicData[1], magicData[2], magicData[3]), translationType: .rawData(4)))
        translations.append(Translation(definition: "CPU Type", humanReadable: self.cpuType.name, translationType: .numberEnum32Bit))
        translations.append(Translation(definition: "CPU Sub Type", humanReadable: self.cpuSubtype.name, translationType: .numberEnum32Bit))
        translations.append(Translation(definition: "Macho Type", humanReadable: self.machoType.readable, translationType: .numberEnum32Bit))
        translations.append(Translation(definition: "Number of load commands", humanReadable: "\(self.numberOfLoadCommands)", translationType: .uint32))
        translations.append(Translation(definition: "Size of all load commands", humanReadable: self.sizeOfAllLoadCommand.hex, translationType: .uint32))
        translations.append(Translation(definition: "Flags", humanReadable: MachoHeader.flagsDescriptionFrom(self.flags), translationType: .flags(4)))
        if let reserved = self.reserved { translations.append(Translation(definition: "Reverved", humanReadable: reserved.hex, translationType: .uint32)) }
        await self.save(translations: translations)
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

struct Macho: File {
    
    static let Magic32: [UInt8] = [0xce, 0xfa, 0xed, 0xfe]
    static let Magic64: [UInt8] = [0xcf, 0xfa, 0xed, 0xfe]
    
    let machoData: Data
    var fileSize: Int { machoData.count }
    
    let machoFileName: String
    let machoHeader: MachoHeader
    var is64Bit: Bool { machoHeader.is64Bit }
    
    let allElements: [MachoBaseElement]
    
    init(with location: FileLocation) throws {
        let fileHandle = try FileHandle(location)
        defer { try? fileHandle.close() }
        let machoData: Data = try fileHandle.assertReadToEnd()
        let machoFileName: String = location.fileName
        self.init(with: machoData, machoFileName: machoFileName)
    }
    
    init(with machoData: Data, machoFileName: String) {
        let is64Bit: Bool
        let magic = machoData[0..<4]
        if magic == Data(Macho.Magic64) {
            is64Bit = true
        } else if magic == Data(Macho.Magic32) {
            is64Bit = false
        } else {
            fatalError() /* what the hell is going on */
        }
        let machoHeader = MachoHeader(from: machoData, is64Bit: is64Bit)
        
        self.machoData = machoData
        self.machoFileName = machoFileName
        self.machoHeader = machoHeader
        
        let tick = TickTock()
        
        var loadCommands: [LoadCommand] = []
        var lcSegmentCommands: [LCSegment] = []
        var lcLinkedITDataCommands: [LCLinkedITData] = []
        var lcDyldInfo: LCDyldInfo?
        
        var sections: [MachoBaseElement] = []
        var allCStrngSections: [CStringSection] = []
        var machoSectionHeaders: [SectionHeader] = []
        var relocationTables: [RelocationTable] = []
        
        var stringTable: StringTable?
        var symbolTable: SymbolTable?
        var indirectSymbolTable: IndirectSymbolTable?
        
        var linkedITSections: [MachoBaseElement] = []
        var dyldInfoSections: [MachoBaseElement] = []
        
        loadCommands = LoadCommand.loadCommands(from: machoData, machoHeader: machoHeader, onLCSegment: {lcSegment in
            lcSegmentCommands.append(lcSegment)
            machoSectionHeaders.append(contentsOf: lcSegment.sectionHeaders)
            if let relocationTable = lcSegment.relocationTable(machoData: machoData, machoHeader: machoHeader) {
                relocationTables.append(relocationTable)
            }
        }, onLCSymbolTable: { lcSymbolTable in
            stringTable = StringTable(stringTableOffset: Int(lcSymbolTable.stringTableOffset),
                                      sizeOfStringTable: Int(lcSymbolTable.sizeOfStringTable),
                                      machoData: machoData)
            symbolTable = SymbolTable(symbolTableOffset: Int(lcSymbolTable.symbolTableOffset),
                                      numberOfSymbolTableEntries: Int(lcSymbolTable.numberOfSymbolTableEntries),
                                      machoData: machoData,
                                      machoHeader: machoHeader, stringTable: stringTable,
                                      machoSectionHeaders: machoSectionHeaders)
        }, onLCDynamicSymbolTable: { lcDynamicSymbolTable in
            indirectSymbolTable = lcDynamicSymbolTable.indirectSymbolTable(machoData: machoData, machoHeader: machoHeader, symbolTable: symbolTable)
        }, onLCLinkedITData: {
            lcLinkedITDataCommands.append($0)
        }, onLCDyldInfo: {
            guard lcDyldInfo == nil else { fatalError() }
            lcDyldInfo = $0
        })
        
        sections = machoSectionHeaders.map({ sectionHeader in
            MachoSection.createSection(allCStrngSections: allCStrngSections,
                                       indirectSymbolTable: indirectSymbolTable,
                                       machoData: machoData,
                                       machoHeader: machoHeader,
                                       sectionHeader: sectionHeader)
        })
        
        allCStrngSections = sections.compactMap({ $0 as? CStringSection })

        linkedITSections = lcLinkedITDataCommands.map { lcLinkedITData in
            lcLinkedITData.linkedITSection(from: machoData,
                                           machoHeader: machoHeader,
                                           textSegmentLoadCommand: lcSegmentCommands.first { $0.segmentName == "__TEXT" },
                                           symbolTable: symbolTable)
        }
        
        if let lcDyldInfo {
            dyldInfoSections = lcDyldInfo.dyldInfoSections(machoData: machoData, machoHeader: machoHeader)
        }
        
        var allElements: [MachoBaseElement] = [machoHeader]
        allElements.append(contentsOf: loadCommands)
        allElements.append(contentsOf: sections)
        allElements.append(contentsOf: relocationTables)
        allElements.append(contentsOf: linkedITSections)
        allElements.append(contentsOf: dyldInfoSections)
        
        if let symbolTable { allElements.append(symbolTable) }
        if let indirectSymbolTable { allElements.append(indirectSymbolTable) }
        if let stringTable { allElements.append(stringTable) }
        
        self.allElements = allElements
        
        tick.tock("Macho Init Completed")
    }
    
}
