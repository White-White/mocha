//
//  Segment.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class Segment: LoadCommand {
    
    let segmentName: String
    let vmaddr: UInt64
    let vmsize: UInt64
    let fileoff: UInt64
    let size: UInt64
    let maxprot: UInt32
    let initprot: UInt32
    let numberOfSections: UInt32
    let flags: Data
    let sectionHeaders: [SectionHeader]
    
    override init(with loadCommandData: SmartData, loadCommandType: LoadCommandType) {
        
        let is64BitSegment = loadCommandType == LoadCommandType.segment64
        var dataShifter = DataShifter(loadCommandData)
        dataShifter.ignore(8) // skip basic data
        
        guard let segmentName = dataShifter.shift(16).utf8String else { fatalError() /* Unlikely */ }
        self.segmentName = segmentName.spaceRemoved
        self.vmaddr = (is64BitSegment ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.vmsize = (is64BitSegment ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.fileoff = (is64BitSegment ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.size = (is64BitSegment ? dataShifter.nextQuadWord() : dataShifter.nextDoubleWord()).UInt64
        self.maxprot = dataShifter.nextDoubleWord().UInt32
        self.initprot = dataShifter.nextDoubleWord().UInt32
        self.numberOfSections = dataShifter.nextDoubleWord().UInt32
        self.flags = dataShifter.nextDoubleWord()
        
        self.sectionHeaders = (0..<numberOfSections).reduce([]) { sectionHeaders, _ in
            // section header data length for 32-bit is 68, and 64-bit 80
            let sectionHeaderLength = is64BitSegment ? 80 : 68
            let sectionHeaderData = loadCommandData.truncated(from: dataShifter.shifted, length: sectionHeaderLength)
            let sectionHeader = SectionHeader(is64Bit: is64BitSegment, data: sectionHeaderData)
            dataShifter.ignore(sectionHeaderLength)
            return sectionHeaders + [sectionHeader]
        }
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override var numberOfTranslationSections: Int {
        return super.numberOfTranslationSections + sectionHeaders.count
    }
    
    override func translationSection(at index: Int) -> TransSection {
        if index >= self.numberOfTranslationSections { fatalError() }
        if index == 0 {
            let is64BitSegment = self.loadCommandType == LoadCommandType.segment64
            let section = super.translationSection(at: index)
            section.translateNext(16) { Readable(description: "Segment Name: ", explanation: "\(self.segmentName)") }
            section.translateNext(is64BitSegment ? 8 : 4) { Readable(description: "vmaddr: ", explanation: "\(self.vmaddr.hex)") } //FIXME: add explanation
            section.translateNext(is64BitSegment ? 8 : 4) { Readable(description: "vmsize: ", explanation: "\(self.vmsize.hex)") } //FIXME: add explanation
            section.translateNext(is64BitSegment ? 8 : 4) { Readable(description: "file offset of this segment: ", explanation: "\(self.fileoff.hex)") } //FIXME: add explanation
            section.translateNext(is64BitSegment ? 8 : 4) { Readable(description: "amount to map from the file: ", explanation: "\(self.size.hex)") } //FIXME: add explanation
            section.translateNextDoubleWord { Readable(description: "maxprot: ", explanation: "\(self.maxprot)") } //FIXME: add explanation
            section.translateNextDoubleWord { Readable(description: "initprot: ", explanation: "\(self.initprot)") } //FIXME: add explanation
            section.translateNextDoubleWord { Readable(description: "numberOfSections: ", explanation: "\(self.numberOfSections)") } //FIXME: add explanation
            section.translateNextDoubleWord { Readable(description: "Flags", explanation: "//FIXME:") } //FIXME: add explanation
            return section
        } else {
            return sectionHeaders[index - 1].makeTranslationSection()
        }
    }
}
