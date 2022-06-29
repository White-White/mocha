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

struct RelocationEntry: InterpretableModel {
    
    let address: UInt32
    let symbolNum: UInt32 // 24 bits
    let pcRelocated: Bool // 1 bit
    let length: UInt8 // 2 bits
    let isExternal: Bool // 1 bit
    let type: UInt8 // 4
    
    let translationStore: TranslationStore
    
    init(with data: DataSlice, is64Bit: Bool, macho: Macho) {
        
        let translationStore = TranslationStore(machoDataSlice: data)
        
        self.address = translationStore.translate(next: .doubleWords,
                                                dataInterpreter: DataInterpreterPreset.UInt32,
                                                itemContentGenerator: { value in TranslationItemContent(description: "Address", explanation: value.hex) })
        
        self.symbolNum = translationStore.translate(next: .rawNumber(3),
                                                  dataInterpreter: { ([UInt8(0)] + $0).UInt32 },
                                                  itemContentGenerator: { value in TranslationItemContent(description: "symbolNum", explanation: "\(value)") })
        
        let rangeOfLastByte = data.absoluteRange(7, 1)
        let lastByte = data.truncated(from: 7, length: 1).raw.UInt8
        
        let pcRelocated = (lastByte & 0b10000000) != 0
        self.pcRelocated = pcRelocated
        
        let length = UInt8((lastByte & 0b01100000) >> 4)
        self.length = length
        
        let isExternal = (lastByte & 0b00010000) != 0
        self.isExternal = isExternal
        
        let type = UInt8((lastByte & 0b00001111) >> 4)
        self.type = type
        
        translationStore.append(TranslationItemContent(description: "extra", explanation: "pcRelocated: \(self.pcRelocated), length: \(self.length), isExternal: \(self.isExternal), type: \(self.type)"),
                              forRange: rangeOfLastByte)
        
        self.translationStore = translationStore
    }
    
    func translationItem(at index: Int) -> TranslationItem {
        return translationStore.items[index]
    }

    static func modelSize(is64Bit: Bool) -> Int {
        return 8
    }
    
    static func numberOfTranslationItems() -> Int {
        return 1
    }
}
