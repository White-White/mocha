//
//  Segment.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class Segment: LoadCommand {
    
    let is64Bit: Bool
    let segmentName: String
    let vmaddr: UInt64
    let vmsize: UInt64
    let fileoff: UInt64
    let segmentSize: UInt64
    let maxprot: UInt32
    let initprot: UInt32
    let numberOfSections: UInt32
    let flags: UInt32
    let sectionHeaders: [SectionHeader]
    
    override var componentSubTitle: String { type.name + " (\(segmentName))" }
    
    required init(with type: LoadCommandType, data: DataSlice, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        let is64Bit = type == LoadCommandType.segment64
        self.is64Bit = is64Bit
        
        self.segmentName = translationStore.translate(next: .rawNumber(16),
                                                    dataInterpreter: { $0.utf8String!.spaceRemoved /* Unlikely Error */ },
                                                        itemContentGenerator: { segmentName in TranslationItemContent(description: "Segment Name", explanation: segmentName) })
        
        self.vmaddr = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                               dataInterpreter: { $0.UInt64 },
                                               itemContentGenerator: { value in TranslationItemContent(description: "vmaddr", explanation: value.hex) })
        
        self.vmsize = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                               dataInterpreter: { $0.UInt64 },
                                               itemContentGenerator: { value in TranslationItemContent(description: "vmsize", explanation: value.hex) })
        
        self.fileoff = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                               dataInterpreter: { $0.UInt64 },
                                               itemContentGenerator: { value in TranslationItemContent(description: "File Offset", explanation: value.hex) })
        
        self.segmentSize = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                               dataInterpreter: { $0.UInt64 },
                                               itemContentGenerator: { value in TranslationItemContent(description: "Amount to map", explanation: value.hex) })
        
        self.maxprot = translationStore.translate(next: .doubleWords,
                                               dataInterpreter: DataInterpreterPreset.UInt32,
                                               itemContentGenerator: { value in TranslationItemContent(description: "maxprot", explanation: "\(value)") })
        
        self.initprot = translationStore.translate(next: .doubleWords,
                                               dataInterpreter: DataInterpreterPreset.UInt32,
                                               itemContentGenerator: { value in TranslationItemContent(description: "initprot", explanation: "\(value)") })
        
        self.numberOfSections = translationStore.translate(next: .doubleWords,
                                               dataInterpreter: DataInterpreterPreset.UInt32,
                                               itemContentGenerator: { value in TranslationItemContent(description: "Number of Sections", explanation: "\(value)") })
        
        self.flags = translationStore.translate(next: .doubleWords,
                                              dataInterpreter: { $0.UInt32 },
                                              itemContentGenerator: { flags in TranslationItemContent(description: "Flags",
                                                                                                      explanation: Segment.flags(for: flags)) })
        
        var sectionHeaders: [SectionHeader] = []
        for index in 0..<Int(numberOfSections) {
            // section header data length for 32-bit is 68, and 64-bit 80
            let sectionHeaderLength = is64Bit ? 80 : 68
            let segmentCommandSize = is64Bit ? 72 : 56
            let sectionHeaderData = data.truncated(from: segmentCommandSize + index * sectionHeaderLength, length: sectionHeaderLength)
            let sectionHeader = SectionHeader(is64Bit: is64Bit, data: sectionHeaderData)
            sectionHeaders.append(sectionHeader)
        }
        self.sectionHeaders = sectionHeaders
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
    
    override var numberOfTranslationItems: Int {
        return super.numberOfTranslationItems + sectionHeaders.count * SectionHeader.numberOfTranslationItems(is64Bit: self.is64Bit)
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        if index < super.numberOfTranslationItems {
            return super.translationItem(at: index)
        } else {
            let targetIndex = index - super.numberOfTranslationItems
            let sectionHeaderIndex = targetIndex / SectionHeader.numberOfTranslationItems(is64Bit: self.is64Bit)
            let sectionHeaderOffset = targetIndex % SectionHeader.numberOfTranslationItems(is64Bit: self.is64Bit)
            return self.sectionHeaders[sectionHeaderIndex].translationStore.items[sectionHeaderOffset]
        }
    }
    
    static func flags(for flags: UInt32) -> String {
        
//        /* Constants for the flags field of the segment_command */
//        #define    SG_HIGHVM    0x1    /* the file contents for this segment is for
//                           the high part of the VM space, the low part
//                           is zero filled (for stacks in core files) */
//        #define    SG_FVMLIB    0x2    /* this segment is the VM that is allocated by
//                           a fixed VM library, for overlap checking in
//                           the link editor */
//        #define    SG_NORELOC    0x4    /* this segment has nothing that was relocated
//                           in it and nothing relocated to it, that is
//                           it maybe safely replaced without relocation*/
//        #define SG_PROTECTED_VERSION_1    0x8 /* This segment is protected.  If the
//                               segment starts at file offset 0, the
//                               first page of the segment is not
//                               protected.  All other pages of the
//                               segment are protected. */
//        #define SG_READ_ONLY    0x10 /* This segment is made read-only after fixups */
        
        var ret: [String] = []
        if (flags & 0x1 != 0) { ret.append("SG_HIGHVM") }
        
        if (flags & 0x2 != 0) { ret.append("SG_FVMLIB") }
        
        if (flags & 0x4 != 0) { ret.append("SG_NORELOC") }
        
        if (flags & 0x8 != 0) { ret.append("SG_PROTECTED_VERSION_1") }
        
        if (flags & 0x10 != 0) { ret.append("SG_READ_ONLY") }
            
        if ret.isEmpty { ret.append("NONE") }
    
        return ret.joined(separator: "\n")
    }
}
