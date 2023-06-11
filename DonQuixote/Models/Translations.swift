//
//  Translations.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/18.
//

import Foundation

class BaseTranslation: @unchecked Sendable {
    
    var dataRangeInMacho: Range<UInt64>?
    let bytesCount: UInt64
    
    init(bytesCount: UInt64) {
        self.bytesCount = bytesCount
    }
    
}

enum TranslationDataType {
    
    case uint8
    case uint16
    case uint32
    case uint64
    case int8
    case int16
    case int32
    case int64
    case versionString
    case numberEnum
    case utf8String
    case utf16String
    case rawData
    case uleb
    case uleb128
    case flags
    case code
    
    var description: String {
        switch self {
        case .uint8:
            return "Unsigned Int-8"
        case .uint16:
            return "Unsigned Int-16"
        case .uint32:
            return "Unsigned Int-32"
        case .uint64:
            return "Unsigned Int-64"
        case .int8:
            return "Signed Int-8"
        case .int16:
            return "Signed Int-16"
        case .int32:
            return "Signed Int-32"
        case .int64:
            return "Signed Int-64"
        case .versionString:
            return "Semantic Version"
        case .numberEnum:
            return "Number Enum"
        case .utf8String:
            return "String-UTF8"
        case .utf16String:
            return "String-UTF16"
        case .rawData:
            return "Raw Data"
        case .uleb:
            return "ULEB"
        case .uleb128:
            return "ULEB-128"
        case .flags:
            return "Bit Flags"
        case .code:
            return "Machine Code"
        }
    }
    
}

class GeneralTranslation: BaseTranslation {
    
    let definition: String?
    let humanReadable: String
    let extraDefinition: String?
    let extraHumanReadable: String?
    let translationType: TranslationDataType
    
    init(definition: String?,
         humanReadable: String,
         bytesCount: Int,
         translationType: TranslationDataType,
         extraDefinition: String? = nil,
         extraHumanReadable: String? = nil) {
        self.definition = definition
        self.humanReadable = humanReadable
        self.translationType = translationType
        self.extraDefinition = extraDefinition
        self.extraHumanReadable = extraHumanReadable
        super.init(bytesCount: UInt64(bytesCount))
    }
    
}

class InstructionTranslation: BaseTranslation {
    
    let capstoneInstruction: CapStoneInstruction
    
    init(capstoneInstruction: CapStoneInstruction) {
        self.capstoneInstruction = capstoneInstruction
        super.init(bytesCount: UInt64(capstoneInstruction.size))
    }
    
}
