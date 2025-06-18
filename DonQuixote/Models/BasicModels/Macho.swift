//
//  Macho.swift
//  mocha
//
//  Created by white on 2021/6/16.
//

import Foundation

class Macho: File {
    
    static let Magic32: [UInt8] = [0xce, 0xfa, 0xed, 0xfe]
    static let Magic64: [UInt8] = [0xcf, 0xfa, 0xed, 0xfe]
    
    let machoData: Data
    var fileSize: Int { machoData.count }
    let machoFileName: String
    let is64Bit: Bool
    
    let machoHeader: MachoHeader
    let loadCommands: [LoadCommand]
    
    private(set) var sectionHeaders: [SectionHeader] = []
    private(set) var machoSections: [MachoPortion] = []
    private(set) var cStringSections: [CStringSection] = []
    private(set) var stringTable: StringTable?
    private(set) var symbolTable: SymbolTable?
    private(set) var indirectSymbolTable: IndirectSymbolTable?
    private(set) var relocationTable: [RelocationTable] = []
    private(set) var linkedITSection: [MachoPortion] = []
    private(set) var dyldInfoSections: [MachoPortion] = []
    
    lazy var allMachoPortions: [MachoPortion] = {
        var _allPortions: [MachoPortion] = []
        _allPortions += [machoHeader]
        _allPortions += loadCommands
        _allPortions += machoSections
        _allPortions += relocationTable
        _allPortions += linkedITSection
        _allPortions += dyldInfoSections
        _allPortions += (symbolTable != nil ? [symbolTable!] : [])
        _allPortions += (indirectSymbolTable != nil ? [indirectSymbolTable!] : [])
        _allPortions += (stringTable != nil ? [stringTable!] : [])
        _allPortions.sort(by: { $0.offsetInMacho < $1.offsetInMacho })
        return _allPortions
    }()
    
    required convenience init(with location: FileLocation) throws {
        let fileHandle = try FileHandle(location)
        defer { try? fileHandle.close() }
        let machoData: Data = try fileHandle.assertReadToEnd()
        let machoFileName: String = location.fileName
        self.init(with: machoData, machoFileName: machoFileName)
    }
    
    init(with machoData: Data, machoFileName: String) {
        
        self.machoData = machoData
        self.machoFileName = machoFileName
        
        let is64Bit: Bool
        let magic = machoData[0..<4]
        if magic == Data(Macho.Magic64) {
            is64Bit = true
        } else if magic == Data(Macho.Magic32) {
            is64Bit = false
        } else {
            /* impossible unless the macho is malformatted */
            fatalError()
        }
        
        self.is64Bit = is64Bit
        let machoHeader = MachoHeader(from: machoData, is64Bit: is64Bit)
        self.machoHeader = machoHeader
        
        let tick = TickTock()
        
        let loadCommandsData = machoData.subSequence(from: machoHeader.dataSize, count: Int(machoHeader.sizeOfAllLoadCommand))
        let loadCommands: [LoadCommand] = LoadCommand.loadCommands(from: loadCommandsData)
        guard loadCommands.count == Int(machoHeader.numberOfLoadCommands) else {
            /* impossible unless the macho is malformatted */
            fatalError()
        }
        self.loadCommands = loadCommands
        
        loadCommands.forEach { loadCommand in
            
            if loadCommand is LCSegment {
                let lcSegment = loadCommand as! LCSegment
                self.sectionHeaders.append(contentsOf: lcSegment.sectionHeaders)
                
                let machoSections = lcSegment.sectionHeaders.map { sectionHeader in
                    Macho.createSection(macho: self, sectionHeader: sectionHeader)
                }
                self.machoSections.append(contentsOf: machoSections)
                self.cStringSections.append(contentsOf: machoSections.compactMap({ $0 as? CStringSection }))
                
                if let relocationTable = lcSegment.relocationTable(machoData: machoData, machoHeader: machoHeader) {
                    self.relocationTable.append(relocationTable)
                }
                
                return
            }
            
            if loadCommand is LCSymbolTable {
                let lcSymbolTable = loadCommand as! LCSymbolTable
                let stringTable = StringTable(stringTableOffset: Int(lcSymbolTable.stringTableOffset),
                                              sizeOfStringTable: Int(lcSymbolTable.sizeOfStringTable),
                                              machoData: machoData)
                let symbolTable = SymbolTable(macho: self,
                                              symbolTableOffset: Int(lcSymbolTable.symbolTableOffset),
                                              numberOfSymbolTableEntries: Int(lcSymbolTable.numberOfSymbolTableEntries))
                self.stringTable = stringTable
                self.symbolTable = symbolTable
                
                return
            }
            
            if loadCommand is LCDynamicSymbolTable {
                let lcDynamicSymbolTable = loadCommand as! LCDynamicSymbolTable
                self.indirectSymbolTable = lcDynamicSymbolTable.indirectSymbolTable(machoData: machoData, machoHeader: machoHeader, symbolTable: symbolTable)
                
                return
            }
            
            if loadCommand is LCLinkedITData {
                let lcLinkedITData = loadCommand as! LCLinkedITData
                let linkedITSection = lcLinkedITData.linkedITSection(macho: self)
                self.linkedITSection.append(linkedITSection)
                
                return
            }
            
            if loadCommand is LCDyldInfo {
                let lcDyldInfo = loadCommand as! LCDyldInfo
                let dyldInfoSections = lcDyldInfo.dyldInfoSections(machoData: machoData, machoHeader: machoHeader)
                self.dyldInfoSections.append(contentsOf: dyldInfoSections)
                
                return
            }
            
        }
        
        tick.tock("Macho Init Completed")
    }
    
}

extension Macho {
    
    static func createSection(macho: Macho, sectionHeader: SectionHeader) -> MachoPortion {
        
        let is64Bit = macho.is64Bit
        let title = sectionHeader.segment + "," + sectionHeader.section
        
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
            return ZeroFilledSection(runtimeSize: Int(sectionHeader.size), title: title)
            
        case .S_CSTRING_LITERALS:
            let data = macho.machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return CStringSection(virtualAddress: sectionHeader.addr, data: data, title: title)
        case .S_LITERAL_POINTERS:
            let data = macho.machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            let allCStrngSections = macho.cStringSections
            return LiteralPointerComponent(allCStringSections: allCStrngSections, data: data, is64Bit: is64Bit, title: title)
        case .S_LAZY_SYMBOL_POINTERS, .S_NON_LAZY_SYMBOL_POINTERS, .S_LAZY_DYLIB_SYMBOL_POINTERS:
            let data = macho.machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            let indirectSymbolTable = macho.indirectSymbolTable
            return SymbolPointerComponent(indirectSymbolTable: indirectSymbolTable, sectionHeader: sectionHeader, data: data, is64Bit: is64Bit, title: title)
        default:
            break
        }
        
        // recognize section by section attributes
        if sectionHeader.sectionAttributes.hasAttribute(.S_ATTR_PURE_INSTRUCTIONS) {
            let data = macho.machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return InstructionSection(data, title: title, cpuType: macho.machoHeader.cpuType, virtualAddress: sectionHeader.addr)
        }
        
        // recognize section by section name
        let data = macho.machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size), allowZeroLength: true)
        switch sectionHeader.segment {
        case "__TEXT":
            switch sectionHeader.section {
            case "__const":
                return TextConstSection(data, title: title, subTitle: nil)
            case "__ustring":
                return UStringSection(data: data, title: title, subTitle: nil)
            case "__swift5_reflstr":
                // https://knight.sc/reverse%20engineering/2019/07/17/swift-metadata.html
                // a great article on introducing swift metadata sections
                return CStringSection(virtualAddress: sectionHeader.addr, data: data, title: title)
            case "__swift5_protos":
                return SwiftMetadataSection<ProtocolDescriptor>(data, title: title, virtualAddress: sectionHeader.addr)
            case "__swift5_proto":
                return SwiftMetadataSection<ProtocolConformanceDescriptor>(data, title: title, virtualAddress: sectionHeader.addr)
            case "__swift5_types":
                fallthrough
            default:
                return UnknownSection(data, title: title, subTitle: nil)
            }
        default:
            return UnknownSection(data, title: title, subTitle: nil)
        }
    }
    
}
