//
//  RebaseOperationCode.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/13.
//

import Foundation

enum RebaseImmediateType {
    
    case rebaseTypePointer
    case rebaseTypeTextAbsolute32
    case rebaseTypeTextPCRel32
    
    case rawValue(UInt8)
    
    var readable: String {
        switch self {
        case .rebaseTypePointer:
            return "REBASE_TYPE_POINTER"
        case .rebaseTypeTextAbsolute32:
            return "REBASE_TYPE_TEXT_ABSOLUTE32"
        case .rebaseTypeTextPCRel32:
            return "REBASE_TYPE_TEXT_PCREL32"
        case .rawValue(let value):
            return "\(value)"
        }
    }
}

enum RebaseOperationType: UInt8 {
    case done = 0x00
    case setTypeImm = 0x10
    case setSegmentAndOffsetULEB = 0x20
    case addAddrULEB = 0x30
    case addAddrImmScaled = 0x40
    case doRebaseImmTimes = 0x50
    case doRebaseULEBTimes = 0x60
    case doRebaseAddAddrULEB = 0x70
    case doRebaseULEBTimesSkippingULEB = 0x80
    
    var readable: String {
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
}

struct RebaseOperationCode: OperationCodeProtocol {
    
    let operationType: RebaseOperationType
    let immediateType: RebaseImmediateType
    let hasTrailingCString: Bool = false
    
    init(operationCodeValue: UInt8, immediateValue: UInt8) {
        guard let operationType = RebaseOperationType(rawValue: operationCodeValue) else {
            // unknown opcode. The latest open sourced dyld doesn's recognize this value neither 😄
            // contact the author
            fatalError()
        }
        self.operationType = operationType
        
        switch operationType {
        case .setTypeImm:
            switch immediateValue {
            case 1:
                self.immediateType = .rebaseTypePointer
            case 2:
                self.immediateType = .rebaseTypeTextAbsolute32
            case 3:
                self.immediateType = .rebaseTypeTextPCRel32
            default:
                fatalError()
            }
        default:
            self.immediateType = .rawValue(immediateValue)
        }
    }
    
    func operationReadable() -> String {
        self.operationType.readable
    }
    
    var numberOfTrailingLEB: Int {
        switch self.operationType {
        case .doRebaseULEBTimesSkippingULEB:
            return 2
        case .setSegmentAndOffsetULEB, .addAddrULEB, .doRebaseULEBTimes, .doRebaseAddAddrULEB:
            return 1
        default:
            return 0
        }
    }
    
    var trailingLEBType: LEBType {
        return .unsigned
    }
    
    
    func immediateReadable() -> String {
        return self.immediateType.readable
    }
}
