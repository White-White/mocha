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

struct RelocationEntry: BinaryTranslationStoreGenerator {
    
    static let length = 8
    
    let offsetInMacho: Int
    let data: SmartData
    var dataSize: Int { data.count }
    
    let address: UInt32
    let symbolNum: UInt32 // 24 bits
    let pcRelocated: Bool // 1 bit
    let length: UInt8 // 2 bits
    let isExternal: Bool // 1 bit
    let type: UInt8 // 4
    
    init(from data: SmartData, offsetInMacho: Int) {
        self.offsetInMacho = offsetInMacho
        self.data = data
        self.address = data.select(from: 0, length: 4).realData.UInt32
        self.symbolNum = ([UInt8(0)] + data.select(from: 4, length: 3).realData).UInt32
        let lastByte = data.select(from: 7, length: 1).realData.first!
        self.pcRelocated = (lastByte & 0b10000000) != 0
        self.length = UInt8((lastByte & 0b01100000) >> 4)
        self.isExternal = (lastByte & 0b00010000) != 0
        self.type = UInt8((lastByte & 0b00001111) >> 4)
    }
    
    func binaryTranslationStore() -> BinaryTranslationStore {
        var store = BinaryTranslationStore(data: self.data, baseDataOffset: self.offsetInMacho)
        store.translateNextDoubleWord { Readable(description: "Address", explanation: self.address.hex, dividerName: "Relocation Entry") }
        store.translateNext(3) { Readable(description: "symbolNum", explanation: "\(self.symbolNum)") }
        store.translateNext(1) { Readable(description: "extra", explanation: "pcRelocated: \(self.pcRelocated), length: \(self.length), isExternal: \(self.isExternal), type: \(self.type)") }
        //FIXME: better explanations
        return store
    }
}

struct Relocation: Identifiable, BinaryTranslationStoreGenerator {
    
    let id = UUID()
    var entries: [RelocationEntry] = []
    var offsetInMacho: Int { entries.first!.offsetInMacho }
    var dataSize: Int { entries.count * RelocationEntry.length }
    
    mutating func addEntries(from entriesData: SmartData, offsetInMacho: Int) {
        let realData = entriesData.realData
        for i in 0..<(realData.count/RelocationEntry.length) {
            let entryOffset = i * RelocationEntry.length
            let relocationEntryData = entriesData.select(from: entryOffset, length: RelocationEntry.length)
            entries.append(RelocationEntry(from: relocationEntryData, offsetInMacho: offsetInMacho + entryOffset))
        }
    }
    
    func binaryTranslationStore() -> BinaryTranslationStore {
        var store = entries.first!.binaryTranslationStore()
        entries.dropFirst().forEach { store.merge(with: $0.binaryTranslationStore()) }
        return store
    }
}
