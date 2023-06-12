//
//  DataInCodeSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

struct DataInCodeEntry {
    
    enum DataInCodeKind: UInt16 {
        case data = 0x1
        case jumpTable8
        case jumpTable16
        case jumpTable32
        case absJumpTable32
        
        var name: String {
            switch self {
            case .data:
                return "DICE_KIND_DATA"
            case .jumpTable8:
                return "DICE_KIND_JUMP_TABLE8"
            case .jumpTable16:
                return "DICE_KIND_JUMP_TABLE16"
            case .jumpTable32:
                return "DICE_KIND_JUMP_TABLE32"
            case .absJumpTable32:
                return "DICE_KIND_ABS_JUMP_TABLE32"
            }
        }
    }
    
    let offset: UInt32
    let length: UInt16
    let kind: DataInCodeKind
    
    init(with data: Data) {
        var dataShifter = DataShifter(data)
        self.offset = dataShifter.shift(.doubleWords).UInt32
        self.length = dataShifter.shift(.word).UInt16
        self.kind = DataInCodeKind(rawValue: dataShifter.shift(.word).UInt16)! /* crash if unknown kind. unlikely */
    }
    
    var translations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(definition: "File Offset", humanReadable: self.offset.hex, translationType: .uint32))
        translations.append(Translation(definition: "Size", humanReadable: "\(self.length)", translationType: .uint16))
        translations.append(Translation(definition: "Kind", humanReadable: self.kind.name, translationType: .numberEnum16Bit))
        return translations
    }
    
    static var EntrySize: Int { 8 }
    
}

class DataInCodeSection: MachoBaseElement {
    
    private var dataInCodeEntries: [DataInCodeEntry] = []

    override func loadTranslations() async {
        let modelSize = DataInCodeEntry.EntrySize
        let numberOfModels = self.dataSize/modelSize
        for index in 0..<numberOfModels {
            let data = self.data.subSequence(from: index * modelSize, count: modelSize)
            let entry = DataInCodeEntry(with: data)
            self.dataInCodeEntries.append(entry)
            await self.save(translationGroup: entry.translations)
        }
    }
    
}
