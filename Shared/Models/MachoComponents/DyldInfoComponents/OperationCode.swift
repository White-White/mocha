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
        
        translations.append(Translation(description: "Operation Code (Upper 4 bits)", explanation: codeMetadata.operationReadable(),
                                        bytesCount: 1,
                                        extraDescription: "Immediate Value Used As (Lower 4 bits)", extraExplanation: codeMetadata.immediateReadable()))
        
        translations.append(contentsOf: lebValues.map { ulebValue in
            Translation(description: "LEB Value", explanation: ulebValue.isSigned ? "\(Int(bitPattern: UInt(ulebValue.raw)))" : "\(ulebValue.raw)",
                        bytesCount: ulebValue.byteCount)
        })
        
        if let cstringData = cstringData {
            let cstring = cstringData.utf8String ?? "🙅‍♂️ Invalid CString"
            translations.append(Translation(description: "String", explanation: cstring, bytesCount: cstringData.count))
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
