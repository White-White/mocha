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

protocol OperationCodeProtocol {
    init(operationCodeValue: UInt8, immediateValue: UInt8)
    func operationReadable() -> String
    func immediateReadable() -> String
    func actionDescription() -> String
    
    var numberOfTrailingLEB: Int { get }
    var trailingLEBType: LEBType { get }
}

struct DyldInfoLEB {
    let absoluteRange: Range<Int>
    let raw: UInt64
    let isSigned: Bool
}

class OperationCode<Code: OperationCodeProtocol> {
    
    let absoluteOffset: Int
    let operationCode: OperationCodeProtocol
    let lebValues: [DyldInfoLEB]
    var numberOfTransItems: Int { 3 + lebValues.count }
    let numberOfTransItemsTotal: Int
    
    lazy var translationItems: [TranslationItem] = {
        var translationItems: [TranslationItem] = []
        translationItems.append(TranslationItem(sourceDataRange: absoluteOffset..<absoluteOffset+1,
                                                content: TranslationItemContent(description: "Operation Code (Upper 4 bits)",
                                                                                explanation: operationCode.operationReadable())))
        translationItems.append(TranslationItem(sourceDataRange: absoluteOffset..<absoluteOffset+1,
                                                content: TranslationItemContent(description: "Immediate Value Used As (Lower 4 bits)",
                                                                                explanation: operationCode.immediateReadable())))
        
        translationItems.append(contentsOf: lebValues.map { ulebValue in
            TranslationItem(sourceDataRange: ulebValue.absoluteRange,
                            content: TranslationItemContent(description: "LEB Value",
                                                            explanation: ulebValue.isSigned ? "\(Int(bitPattern: UInt(ulebValue.raw)))" : ulebValue.raw.hex))
        })
        
        translationItems.append(TranslationItem(sourceDataRange: absoluteOffset..<absoluteOffset+1+(lebValues.last?.absoluteRange.upperBound ?? 0),
                                                content: TranslationItemContent(description: "Action Description",
                                                                                explanation: operationCode.actionDescription())))
        return translationItems
    }()
    
    init(absoluteOffset: Int, operationCode: Code, lebValues:[DyldInfoLEB], numberOfTransItemsTotal: Int) {
        self.absoluteOffset = absoluteOffset
        self.operationCode = operationCode
        self.lebValues = lebValues
        self.numberOfTransItemsTotal = numberOfTransItemsTotal
    }
}
