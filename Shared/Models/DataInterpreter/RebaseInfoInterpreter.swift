//
//  RebaseInfoInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/9.
//

import Foundation

enum RebaseType: UInt8 {
    case pointer = 1
    case textAbsolute32 = 2
    case textPCRel32 = 3
    
    var name: String {
        switch self {
        case .pointer:
            return "REBASE_TYPE_POINTER"
        case .textAbsolute32:
            return "REBASE_TYPE_TEXT_ABSOLUTE32"
        case .textPCRel32:
            return "REBASE_TYPE_TEXT_PCREL32"
        }
    }
}

enum RebaseImmediate {
    case rebaseType(RebaseType)
    case segmentIndex
    case scale
    case count
    case ignored
    
    var meaning: String {
        switch self {
        case .rebaseType(let rebaseType):
            return "Type: \(rebaseType.name)"
        case .segmentIndex:
            return "Segment Index"
        case .scale:
            return "Scale"
        case .count:
            return "Iteration Time"
        case .ignored:
            return "Not Used"
        }
    }
}

enum ULEBValueType {
    case segmentOffset
    case count
    case skip
    
    var meaning: String {
        switch self {
        case .segmentOffset:
            return "Segment Offset"
        case .count:
            return "Iteration Time"
        case .skip:
            return "Skip"
        }
    }
}

struct ULEBValue {
    let range: Range<Int>
    let type: ULEBValueType
    let value: UInt64
    
    var meaning: String {
        return "\(type.meaning). Raw Vaule(\(value.hex))"
    }
}

enum RebaseOperation: UInt8 {
    case done = 0x00
    case setTypeImm = 0x10
    case setSegmentAndOffsetULEB = 0x20
    case addAddrULEB = 0x30
    case addAddrImmScaled = 0x40
    case doRebaseImmTimes = 0x50
    case doRebaseULEBTimes = 0x60
    case doRebaseAddAddrULEB = 0x70
    case doRebaseULEBTimesSkippingULEB = 0x80
    
    var name: String {
        switch self {
        case .done:
            return "REBASE_OPCODE_DONE"
        case .setTypeImm:
            return "REBASE_OPCODE_SET_TYPE_IMM"
        case .setSegmentAndOffsetULEB:
            return "REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB"
        case .addAddrULEB:
            return "REBASE_OPCODE_ADD_ADDR_ULEB"
        case .addAddrImmScaled:
            return "REBASE_OPCODE_ADD_ADDR_IMM_SCALED"
        case .doRebaseImmTimes:
            return "REBASE_OPCODE_DO_REBASE_IMM_TIMES"
        case .doRebaseULEBTimes:
            return "REBASE_OPCODE_DO_REBASE_ULEB_TIMES"
        case .doRebaseAddAddrULEB:
            return "REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB"
        case .doRebaseULEBTimesSkippingULEB:
            return "REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB"
        }
    }
    
    func trailingULEBValueTypes() -> [ULEBValueType] {
        switch self {
        case .done, .setTypeImm, .addAddrImmScaled, .doRebaseImmTimes:
            return []
        case .setSegmentAndOffsetULEB:
            return [.segmentOffset]
        case .addAddrULEB:
            return [.segmentOffset]
        case .doRebaseULEBTimes:
            return [.count]
        case .doRebaseAddAddrULEB:
            return [.segmentOffset]
        case .doRebaseULEBTimesSkippingULEB:
            return [.count, .skip]
        }
    }
    
    func immediateType(with rawValue: UInt8) -> RebaseImmediate {
        switch self {
        case .done:
            return .ignored
        case .setTypeImm:
            guard let rebaseType = RebaseType(rawValue: rawValue) else {
                // off-record REBASE_TYPE.... contact the author
                fatalError()
            }
            return .rebaseType(rebaseType)
        case .setSegmentAndOffsetULEB:
            return .segmentIndex
        case .addAddrULEB:
            return .ignored
        case .addAddrImmScaled:
            return .scale
        case .doRebaseImmTimes:
            return .count
        case .doRebaseULEBTimes:
            return .ignored
        case .doRebaseAddAddrULEB:
            return .ignored
        case .doRebaseULEBTimesSkippingULEB:
            return .ignored
        }
    }
}

struct RebaseOperationInfo {
    
    static let operationCodeMask: UInt8 = 0xf0
    static let immediateMask: UInt8 = 0x0f
    
    let dataRange: Range<Int>
    let operation: RebaseOperation
    let immediate: RebaseImmediate
    let ULEBValues: [ULEBValue]
    
    static func operationInfos(from data: Data) -> [RebaseOperationInfo] {
        var ret: [RebaseOperationInfo] = []
        var index: Int = 0
        
        while index < data.count {
            let startIndexOfCurrentOperation = index
            
            let byte = data[data.startIndex+index]; index += 1
            
            guard let operation = RebaseOperation(rawValue: byte & RebaseOperationInfo.operationCodeMask) else {
                // unknown opcode. The latest open sourced dyld doesn's recognize this value neither 😄
                // contact the author
                fatalError()
            }
            
            let immediateValue = byte & RebaseOperationInfo.immediateMask
            
            // extract trailing ULEB
            var ULEBValues: [ULEBValue] = []
            for ulebValueType in operation.trailingULEBValueTypes() {
                let ulebStartIndex = index
                var delta: Swift.UInt64 = 0
                var shift: Swift.UInt32 = 0
                var more = true
                repeat {
                    let ulebByte = data[data.startIndex+index]; index += 1
                    delta |= ((Swift.UInt64(byte) & 0x7f) << shift)
                    shift += 7
                    if ulebByte < 0x80 {
                        more = false
                    }
                } while (more)
                
                ULEBValues.append(ULEBValue(range: ulebStartIndex..<index, type: ulebValueType, value: delta))
            }
            
            ret.append(RebaseOperationInfo(dataRange: startIndexOfCurrentOperation..<index,
                                           operation: operation,
                                           immediate: operation.immediateType(with: immediateValue),
                                           ULEBValues: ULEBValues))
        }
        return ret
    }
}

class RebaseInfoInterpreter: BaseInterpreter<[RebaseOperationInfo]> {
    
    override var shouldPreload: Bool { true }
    
    override func generatePayload() -> [RebaseOperationInfo] {
        return RebaseOperationInfo.operationInfos(from: self.data.raw)
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.count
    }
    
    override func translationItems(at section: Int) -> [TranslationItem] {
        let rebaseInfo = self.payload[section]
        let infoRange = rebaseInfo.dataRange
        
        var translationTerms: [TranslationItem] = []
        
        translationTerms.append(TranslationItem(sourceDataRange: data.absoluteRange(infoRange.lowerBound, 1),
                                                content: TranslationItemContent(description: "Operation Code (Upper 4 bits)",
                                                                                explanation: rebaseInfo.operation.name)))
        
        translationTerms.append(TranslationItem(sourceDataRange: data.absoluteRange(infoRange.lowerBound, 1),
                                                content: TranslationItemContent(description: "Immediate Meaning (Lower 4 bits)",
                                                                                explanation: rebaseInfo.immediate.meaning)))
        
        for ulebValue in rebaseInfo.ULEBValues {
            translationTerms.append(TranslationItem(sourceDataRange: data.absoluteRange(ulebValue.range),
                                                    content: TranslationItemContent(description: "ULEB Encoded Value With Meaning",
                                                                                    explanation: ulebValue.meaning)))
        }
        
        return translationTerms
    }
    
    override func sectionTitle(of section: Int) -> String? {
        return "Rebase Operation"
    }
}
