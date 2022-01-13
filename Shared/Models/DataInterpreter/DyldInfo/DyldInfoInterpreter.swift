//
//  RebaseInfoInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/9.
//

import Foundation

class DyldInfoInterpreter<Code: OperationCodeProtocol>: BaseInterpreter<[OperationCode<Code>]> {
    
    override var shouldPreload: Bool { true }
    
    override func generatePayload() -> [OperationCode<Code>] {
        return DyldInfoInterpreter.operationCodes(from: self.data)
    }
    
    override var numberOfTranslationItems: Int {
        return self.payload.last?.numberOfTransItemsTotal ?? 0
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        for rebaseInfo in self.payload {
            if index < rebaseInfo.numberOfTransItemsTotal {
                let numberOfTransItemsBeforeCurrent = rebaseInfo.numberOfTransItemsTotal - rebaseInfo.numberOfTransItems
                return rebaseInfo.translationItems[index - numberOfTransItemsBeforeCurrent]
            }
        }
        fatalError()
    }
    
    // parsing
    static func operationCodes(from data: DataSlice) -> [OperationCode<Code>] {
        var opCodes: [OperationCode<Code>] = []
        var index: Int = 0
        let rawData = data.raw
        while index < rawData.count {
            let startIndexOfCurrentOperation = index
            let byte = rawData[rawData.startIndex+index]; index += 1
            let operationCodeValue = byte & 0xf0 // mask the most significant 4 bits
            let immediateValue = byte & 0x0f // mask the least significant 4 bits
            let operationCode = Code.init(operationCodeValue: operationCodeValue, immediateValue: immediateValue)
            
            // trailing LEBs
            // FIXME: compitable with SLEB
            var lebValues: [DyldInfoLEB] = []
            for _ in 0..<operationCode.numberOfTrailingLEB {
                let ulebStartIndex = index
                var delta: Swift.UInt64 = 0
                var shift: Swift.UInt32 = 0
                var more = true
                repeat {
                    let lebByte = rawData[rawData.startIndex+index]; index += 1
                    delta |= ((Swift.UInt64(byte) & 0x7f) << shift)
                    shift += 7
                    if lebByte < 0x80 {
                        more = false
                    }
                } while (more)
                
                let isSigned = operationCode.trailingLEBType == .signed
                if (isSigned) {
                    let signExtendMask: Swift.UInt64 = ~0
                    delta |= signExtendMask << shift
                }
                
                lebValues.append(DyldInfoLEB(absoluteRange:(data.startIndex+ulebStartIndex)..<(data.startIndex+index), raw: delta, isSigned: isSigned))
            }
            
            let numberOfTransItemsBeforeCurrent = opCodes.last?.numberOfTransItemsTotal ?? 0
            let numberOfTransItemsCurrent = lebValues.count + 3
            
            opCodes.append(OperationCode<Code>(absoluteOffset:data.startIndex+startIndexOfCurrentOperation,
                                               operationCode: operationCode,
                                               lebValues: lebValues,
                                               numberOfTransItemsTotal: numberOfTransItemsBeforeCurrent + numberOfTransItemsCurrent))
        }
        return opCodes
    }
}
