//
//  DataInCodeModel.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

struct DataInCodeModel: InterpretableModel {
    
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
    let itemsContainer: TranslationItemContainer
    
    init(with data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey : Any]?) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil)
        
        self.offset = itemsContainer.translate(next: .doubleWords,
                                               dataInterpreter: DataInterpreterPreset.UInt32,
                                               itemContentGenerator: { offset in TranslationItemContent(description: "File Offset", explanation: offset.hex) })
        
        self.length = itemsContainer.translate(next: .word,
                                               dataInterpreter: { $0.UInt16 },
                                               itemContentGenerator: { length in TranslationItemContent(description: "Size", explanation: "\(length)") })
        
        self.kind = itemsContainer.translate(next: .word,
                                             dataInterpreter: { DataInCodeKind(rawValue: $0.UInt16)! /* Unknown Kind. Unlikely */ },
                                             itemContentGenerator: { kind in TranslationItemContent(description: "Kind", explanation: kind.name) })
        
        self.itemsContainer = itemsContainer
    }
    
    func translationItems() -> [TranslationItem] {
        return itemsContainer.items
    }
    
    static func modelSize(is64Bit: Bool) -> Int {
        return 8
    }
}
