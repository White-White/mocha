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
    
    let data: DataSlice
    let offset: UInt32
    let length: UInt16
    let kind: DataInCodeKind
    
    init(with data: DataSlice, is64Bit: Bool) {
        self.data = data
        self.offset = data.truncated(from: 0, length: 4).raw.UInt32
        self.length = data.truncated(from: 4, length: 2).raw.UInt16
        let kindValue = data.truncated(from: 6, length: 2).raw.UInt16
        if let kind = DataInCodeKind(rawValue: kindValue) {
            self.kind = kind
        } else {
            Log.error("Unknown data in code kind value \(kindValue). Debug me.")
            fatalError()
        }
    }
    
    func makeTransSection() -> TransSection {
        let section = TransSection(baseIndex: data.startIndex, title: DataInCodeModel.modelName())
        section.translateNextDoubleWord { Readable(description: "File Offset", explanation: "\(self.offset.hex)") }
        section.translateNext(2) { Readable(description: "Size", explanation: "\(self.length)") }
        section.translateNext(2) {
            Readable(description: "Kind", explanation: self.kind.name)
        }
        return section
    }
    
    static func modelName() -> String? {
        return "Data In Code"
    }
    
    static func modelSize(is64Bit: Bool) -> Int {
        return 8
    }
}
