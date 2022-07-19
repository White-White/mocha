//
//  Translation.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/18.
//

import Foundation

enum TranslationType {
    
    case number
    case numberEnum
    case utf8String
    case utf16String
    case rawData
    case uleb
    case flags
    case code
    
    var description: String {
        switch self {
        case .number:
            return "Number"
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
        case .flags:
            return "Bit Flags"
        case .code:
            return "Machine Code"
        }
    }
    
}

struct Translation {
    
    let definition: String
    let humanReadable: String

    let extraDefinition: String?
    let extraHumanReadable: String?
    
    let translationType: TranslationType
    let bytesCount: UInt64
    
    init(definition: String,
         humanReadable: String,
         bytesCount: Int,
         translationType: TranslationType,
         extraDefinition: String? = nil,
         extraHumanReadable: String? = nil) {
        
        self.definition = definition
        self.humanReadable = humanReadable
        
        self.bytesCount = UInt64(bytesCount)
        self.translationType = translationType
        
        self.extraDefinition = extraDefinition
        self.extraHumanReadable = extraHumanReadable
    }
    
}
