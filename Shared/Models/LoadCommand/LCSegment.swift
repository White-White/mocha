//
//  Segment.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

struct VMProtection {
    
    let raw: UInt32
    let readable: Bool
    let writable: Bool
    let executable: Bool
    
    init(raw: UInt32) {
        self.raw = raw
        self.readable = raw & 0x01 != 0
        self.writable = raw & 0x02 != 0
        self.executable = raw & 0x04 != 0
    }
    
    var explanation: String {
        if readable && writable && executable { return "VM_PROT_ALL" }
        if readable && writable { return "VM_PROT_DEFAULT" }
        var ret: [String] = []
        if readable { ret.append("VM_PROT_READ") }
        if writable { ret.append("VM_PROT_WRITE") }
        if executable { ret.append("VM_PROT_EXECUTE") }
        if ret.isEmpty { ret.append("VM_PROT_NONE") }
        return ret.joined(separator: ",")
    }
}

class LCSegment: LoadCommand {
    
    let is64Bit: Bool
    let segmentName: String
    let vmaddr: UInt64
    let vmsize: UInt64
    let segmentFileOff: UInt64
    let segmentSize: UInt64
    let maxprot: UInt32
    let initprot: UInt32
    let numberOfSections: UInt32
    let flags: UInt32
    let sectionHeaders: [SectionHeader]
    
    override var componentSubTitle: String { type.name + " (\(segmentName))" }
    
    required init(with type: LoadCommandType, data: Data, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(data: data).skip(.quadWords)
        
        let is64Bit = type == LoadCommandType.segment64
        self.is64Bit = is64Bit
        
        self.segmentName = translationStore.translate(next: .rawNumber(16),
                                                    dataInterpreter: { $0.utf8String!.spaceRemoved /* Unlikely Error */ },
                                                        itemContentGenerator: { segmentName in TranslationItemContent(description: "Segment Name", explanation: segmentName) })
        
        self.vmaddr = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                                 dataInterpreter: { is64Bit ? $0.UInt64 : UInt64($0.UInt32) },
                                               itemContentGenerator: { value in TranslationItemContent(description: "Virtual Memory Start Address", explanation: value.hex) })
        
        self.vmsize = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                               dataInterpreter: { is64Bit ? $0.UInt64 : UInt64($0.UInt32) },
                                               itemContentGenerator: { value in TranslationItemContent(description: "Virtual Memory Size", explanation: value.hex) })
        
        self.segmentFileOff = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                                         dataInterpreter: { is64Bit ? $0.UInt64 : UInt64($0.UInt32) },
                                                         itemContentGenerator: { value in TranslationItemContent(description: "File Offset", explanation: value.hex) })
        
        self.segmentSize = translationStore.translate(next: (is64Bit ? .quadWords : .doubleWords),
                                               dataInterpreter: { is64Bit ? $0.UInt64 : UInt64($0.UInt32) },
                                               itemContentGenerator: { value in TranslationItemContent(description: "Size to Map into Memory", explanation: value.hex) })
        
        self.maxprot = translationStore.translate(next: .doubleWords,
                                               dataInterpreter: DataInterpreterPreset.UInt32,
                                               itemContentGenerator: { value in TranslationItemContent(description: "Maximum VM Protection", explanation: VMProtection(raw: value).explanation) })
        
        self.initprot = translationStore.translate(next: .doubleWords,
                                               dataInterpreter: DataInterpreterPreset.UInt32,
                                               itemContentGenerator: { value in TranslationItemContent(description: "Initial VM Protection", explanation: VMProtection(raw: value).explanation) })
        
        self.numberOfSections = translationStore.translate(next: .doubleWords,
                                               dataInterpreter: DataInterpreterPreset.UInt32,
                                               itemContentGenerator: { value in TranslationItemContent(description: "Number of Sections", explanation: "\(value)") })
        
        self.flags = translationStore.translate(next: .doubleWords,
                                              dataInterpreter: { $0.UInt32 },
                                              itemContentGenerator: { flags in TranslationItemContent(description: "Flags",
                                                                                                      explanation: LCSegment.flags(for: flags),
                                                                                                      hasDivider: true) })
        
        var sectionHeaders: [SectionHeader] = []
        for index in 0..<Int(numberOfSections) {
            // section header data length for 32-bit is 68, and 64-bit 80
            let sectionHeaderLength = is64Bit ? 80 : 68
            let segmentCommandSize = is64Bit ? 72 : 56
            let sectionHeaderData = data.subSequence(from: segmentCommandSize + index * sectionHeaderLength, count: sectionHeaderLength)
            let sectionHeader = SectionHeader(is64Bit: is64Bit, data: sectionHeaderData)
            sectionHeaders.append(sectionHeader)
        }
        self.sectionHeaders = sectionHeaders
        
        super.init(with: type, data: data, translationStore: translationStore)
    }
    
    override func numberOfTranslationSections() -> Int {
        return super.numberOfTranslationSections() + sectionHeaders.count
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        switch section {
        case 0:
            return super.numberOfTranslationItems(at: section)
        default:
            return SectionHeader.numberOfTranslationItems(is64Bit: self.is64Bit)
        }
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        switch indexPath.section {
        case 0:
            return super.translationItem(at: indexPath)
        default:
            return self.sectionHeaders[indexPath.section - 1].translationStore.items[indexPath.item]
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
