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
    
    init(with data: Data, is64Bit: Bool, macho: Macho) {
        var dataShifter = DataShifter(data)
        self.offset = dataShifter.shift(.doubleWords).UInt32
        self.length = dataShifter.shift(.word).UInt16
        self.kind = DataInCodeKind(rawValue: dataShifter.shift(.word).UInt16)! /* crash if unknown kind. unlikely */
    }
    
    var translations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(description: "File Offset", explanation: self.offset.hex, bytesCount: Straddle.doubleWords.raw))
        translations.append(Translation(description: "Size", explanation: "\(self.length)", bytesCount: Straddle.word.raw))
        translations.append(Translation(description: "Kind", explanation: self.kind.name, bytesCount: Straddle.word.raw))
        return translations
    }
    
    static var modelSizeFor64Bit: Int { 8 }
    static var modelSizeFor32Bit: Int { 8 }
}
