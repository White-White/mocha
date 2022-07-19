//
//  OperationCode.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/13.
//

import Foundation

enum LEBType {
    case signed
    case unsigned
}

protocol OperationCodeMetadataProtocol {
    init(operationCodeValue: UInt8, immediateValue: UInt8)
    func operationReadable() -> String
    func immediateReadable() -> String
    
    var numberOfTrailingLEB: Int { get }
    var trailingLEBType: LEBType { get }
    var hasTrailingCString: Bool { get }
}

struct DyldInfoLEB {
    let byteCount: Int
    let raw: UInt64
    let isSigned: Bool
}

struct OperationCode<CodeMetadata: OperationCodeMetadataProtocol> {
    
    let codeMetadata: CodeMetadata
    let lebValues: [DyldInfoLEB]
    let cstringData: Data?
    let numberOfTranslations: Int
    
    var translations: [Translation] {
        
        var translations: [Translation] = []
        
        translations.append(Translation(definition: "Operation Code (Upper 4 bits)", humanReadable: codeMetadata.operationReadable(),
                                        bytesCount: 1, translationType: .number,
                                        extraDefinition: "Immediate Value Used As (Lower 4 bits)", extraHumanReadable: codeMetadata.immediateReadable()))
        
        translations.append(contentsOf: lebValues.map { ulebValue in
            Translation(definition: "LEB Value", humanReadable: ulebValue.isSigned ? "\(Int(bitPattern: UInt(ulebValue.raw)))" : "\(ulebValue.raw)",
                        bytesCount: ulebValue.byteCount, translationType: .uleb)
        })
        
        if let cstringData = cstringData {
            let cstring = cstringData.utf8String ?? "🙅‍♂️ Invalid CString"
            translations.append(Translation(definition: "String", humanReadable: cstring, bytesCount: cstringData.count, translationType: .utf8String))
        }
        
        return translations
    }
    
    init(operationCode: CodeMetadata, lebValues:[DyldInfoLEB], cstringData: Data?) {
        self.codeMetadata = operationCode
        self.lebValues = lebValues
        self.cstringData = cstringData
        self.numberOfTranslations = 2 + lebValues.count + (cstringData == nil ? 0 : 1)
    }
}
