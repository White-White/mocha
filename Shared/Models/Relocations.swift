//
//  Relocations.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/17.
//

import Foundation

//struct relocation_info {
//   int32_t    r_address;    /* offset in the section to what is being
//                   relocated */
//   uint32_t     r_symbolnum:24,    /* symbol index if r_extern == 1 or section
//                   ordinal if r_extern == 0 */
//        r_pcrel:1,     /* was relocated pc relative already */
//        r_length:2,    /* 0=byte, 1=word, 2=long, 3=quad */
//        r_extern:1,    /* does not include value of sym referenced */
//        r_type:4;    /* if not 0, machine specific relocation type */
//};

struct RelocationEntry {
    
    static let length = 8
    
    let data: SmartData
    
    let address: UInt32
    let symbolNum: UInt32 // 24 bits
    let pcRelocated: Bool // 1 bit
    let length: UInt8 // 2 bits
    let isExternal: Bool // 1 bit
    let type: UInt8 // 4
    
    init(from data: SmartData) {
        self.data = data
        self.address = data.truncated(from: 0, length: 4).raw.UInt32
        self.symbolNum = ([UInt8(0)] + data.truncated(from: 4, length: 3).raw).UInt32
        let lastByte = data.truncated(from: 7, length: 1).raw.first!
        self.pcRelocated = (lastByte & 0b10000000) != 0
        self.length = UInt8((lastByte & 0b01100000) >> 4)
        self.isExternal = (lastByte & 0b00010000) != 0
        self.type = UInt8((lastByte & 0b00001111) >> 4)
    }
    
    func makeTranslationSection() -> TranslationSection {
        let section = TranslationSection(baseIndex: data.startOffsetInMacho, title: "Relocation Entry")
        section.translateNextDoubleWord { Readable(description: "Address", explanation: self.address.hex) }
        section.translateNext(3) { Readable(description: "symbolNum", explanation: "\(self.symbolNum)") }
        section.translateNext(1) { Readable(description: "extra", explanation: "pcRelocated: \(self.pcRelocated), length: \(self.length), isExternal: \(self.isExternal), type: \(self.type)") }
        //FIXME: better explanations
        return section
    }
}

class Relocation: SmartDataContainer, TranslationStore {
    
    var entries: [RelocationEntry] = []
    var smartData: SmartData
    var numberOfTranslationSections: Int { entries.count }
    
    init(_ entriesData: SmartData) {
        self.smartData = entriesData
        self._addEntries(entriesData)
    }
    
    func addEntries(_ entriesData: SmartData) {
        self.smartData.merge(entriesData)
        self._addEntries(entriesData)
    }
    
    private func _addEntries(_ entriesData: SmartData) {
        var entries: [RelocationEntry] = []
        let raw = entriesData.raw
        for i in 0..<(raw.count/RelocationEntry.length) {
            let entryOffset = i * RelocationEntry.length
            let relocationEntryData = entriesData.truncated(from: entryOffset, length: RelocationEntry.length)
            entries.append(RelocationEntry(from: relocationEntryData))
        }
        self.entries.append(contentsOf: entries)
    }
    
    func translationSection(at index: Int) -> TranslationSection {
        return entries[index].makeTranslationSection()
    }
}
