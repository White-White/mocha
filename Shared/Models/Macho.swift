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

class MachoHeader: MachoComponentWithTranslations {
    
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
        super.init(headerData, title: "Mach Header")
    }
    
    override func createTranslations() -> [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(definition: "Magic", humanReadable: String.init(format: "%0X%0X%0X%0X", magicData[0], magicData[1], magicData[2], magicData[3]), bytesCount: 4, translationType: .rawData))
        translations.append(Translation(definition: "CPU Type", humanReadable: self.cpuType.name, bytesCount: 4, translationType: .numberEnum))
        translations.append(Translation(definition: "CPU Sub Type", humanReadable: self.cpuSubtype.name, bytesCount: 4, translationType: .numberEnum))
        translations.append(Translation(definition: "Macho Type", humanReadable: self.machoType.readable, bytesCount: 4, translationType: .numberEnum))
        translations.append(Translation(definition: "Number of load commands", humanReadable: "\(self.numberOfLoadCommands)", bytesCount: 4, translationType: .uint32))
        translations.append(Translation(definition: "Size of all load commands", humanReadable: self.sizeOfAllLoadCommand.hex, bytesCount: 4, translationType: .uint32))
        translations.append(Translation(definition: "Flags", humanReadable: MachoHeader.flagsDescriptionFrom(self.flags), bytesCount: 4, translationType: .flags))
        if let reserved = self.reserved { translations.append(Translation(definition: "Reverved", humanReadable: reserved.hex, bytesCount: 4, translationType: .uint32)) }
        return translations
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
    
    let machoFileName: String
    let machoHeader: MachoHeader
    var is64Bit: Bool { machoHeader.is64Bit }
    
    let loadCommands: [LoadCommand]
    let sectionHeaders: [SectionHeader]
    let relocationTables: [RelocationTable]
    let sectionComponents: [MachoComponent]
    let linkedITComponents: [MachoComponent]
    let dyldInfoComponents: [MachoComponent]
    
    let allComponents: [MachoComponent]
    lazy var cStringSectionComponents: [CStringSectionComponent] = { allComponents.compactMap { $0 as? CStringSectionComponent } }()
    
    let stringTable: StringTable?
    let symbolTable: SymbolTable?
    let indirectSymbolTable: IndirectSymbolTable?
    let textConstComponent: TextConstComponent?
    
    init(with machoData: Data, machoFileName: String, machoHeader: MachoHeader) {
        self.machoData = machoData
        self.machoFileName = machoFileName
        self.machoHeader = machoHeader
        
        let tick = TickTock()
        
        let loadCommands = LoadCommand.loadCommands(from: machoData.subSequence(from: machoHeader.dataSize, count: Int(machoHeader.sizeOfAllLoadCommand)))
        guard loadCommands.count == Int(machoHeader.numberOfLoadCommands) else { fatalError() }
        self.loadCommands = loadCommands
        
        let segmentCommands = loadCommands.compactMap { $0 as? LCSegment }
        let textSegmentLoadCommand = segmentCommands.first { $0.segmentName == "__TEXT" }
        let sectionHeaders = segmentCommands.flatMap { $0.sectionHeaders }
        self.sectionHeaders = sectionHeaders
        
        let relocationTables = segmentCommands.compactMap { $0.relocationTable(machoData: machoData, machoHeader: machoHeader) }
        self.relocationTables = relocationTables
        
        let symbolTableLoadCommand = (loadCommands.compactMap { $0 as? LCSymbolTable }).first
        self.symbolTable = symbolTableLoadCommand?.symbolTable(machoData: machoData, machoHeader: machoHeader)
        self.stringTable = symbolTableLoadCommand?.stringTable(machoData: machoData)
        
        let indirectSymbolTableLoadCommand = (loadCommands.compactMap { $0 as? LCDynamicSymbolTable }).first
        self.indirectSymbolTable = indirectSymbolTableLoadCommand?.indirectSymbolTable(machoData: machoData, machoHeader: machoHeader)
        
        let sectionComponents = sectionHeaders.compactMap { SectionComponent.createComponent(machoData: machoData, machoHeader: machoHeader, sectionHeader: $0) }
        self.textConstComponent = (sectionComponents.first { $0 is TextConstComponent }) as? TextConstComponent
        self.sectionComponents = sectionComponents
        
        let linkedITDataLoadCommands = loadCommands.compactMap { $0 as? LCLinkedITData }
        let linkedITComponents = linkedITDataLoadCommands.map { $0.linkedITComponent(machoData: machoData, machoHeader: machoHeader, textSegmentLoadCommand: textSegmentLoadCommand) }
        self.linkedITComponents = linkedITComponents
        
        let dyldInfoLoadCommands = (loadCommands.compactMap { $0 as? LCDyldInfo })
        let dyldInfoComponents = dyldInfoLoadCommands.flatMap { $0.dyldInfoComponents(machoData: machoData, machoHeader: machoHeader) }
        self.dyldInfoComponents = dyldInfoComponents
        
        var allComponents: [MachoComponent] = [machoHeader]
        allComponents.append(contentsOf: loadCommands)
        allComponents.append(contentsOf: sectionComponents)
        allComponents.append(contentsOf: relocationTables)
        allComponents.append(contentsOf: linkedITComponents)
        allComponents.append(contentsOf: dyldInfoComponents)
        if let symbolTable = self.symbolTable { allComponents.append(symbolTable) }
        if let indirectSymbolTable = self.indirectSymbolTable { allComponents.append(indirectSymbolTable) }
        if let stringTable = self.stringTable { allComponents.append(stringTable) }
        self.allComponents = allComponents
        self.allComponents.forEach { $0.macho = self }
        tick.tock("Macho Init Completed")
        
        let dependentComponents = Array(Set(self.allComponents.reduce([]) { $0 + $1.dependentComponent }))
        let componentsToTriggerInit = self.allComponents.filter { !dependentComponents.contains($0) }
        componentsToTriggerInit.forEach { $0.startAsyncInitialization() }
        tick.tock("Macho Trigger Component Init Completed")
    }
    
}
