//
//  BindOperationCode.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/13.
//

import Foundation

//#define BIND_TYPE_POINTER                    1
//#define BIND_TYPE_TEXT_ABSOLUTE32                2
//#define BIND_TYPE_TEXT_PCREL32                    3
//
//#define BIND_SPECIAL_DYLIB_SELF                     0
//#define BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE            -1
//#define BIND_SPECIAL_DYLIB_FLAT_LOOKUP                -2
//#define BIND_SPECIAL_DYLIB_WEAK_LOOKUP                -3
//
//#define BIND_SYMBOL_FLAGS_WEAK_IMPORT                0x1
//#define BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION            0x8

// FIXME: consume these symbols

enum BindImmediateType {
    case threadedSubSetBindOrdinalTableSizeULEB
    case threadedSubApple
    case rawValue(UInt8)
    
    var readable: String {
        switch self {
        case .threadedSubSetBindOrdinalTableSizeULEB:
            return "BIND_SUBOPCODE_THREADED_SET_BIND_ORDINAL_TABLE_SIZE_ULEB"
        case .threadedSubApple:
            return "BIND_SUBOPCODE_THREADED_APPLY"
        case .rawValue(let uInt8):
            return "Raw Integer: \(uInt8)"
        }
    }
}

enum BindOperationType: UInt8 {
    case done = 0x00
    case setDylibOrdinalImm = 0x10
    case setDylibOrdinalULEB = 0x20
    case setDylibSpecialImm = 0x30
    case setSymbolTrailingFlagsImm = 0x40
    case setTypeImm = 0x50
    case setAddEndSLEB = 0x60
    case setSegmentAndOffsetULEB = 0x70
    case addAddrULEB = 0x80
    case doBind = 0x90
    case doBindAddAddrULEB = 0xa0
    case doBindAddAddrImmScaled = 0xb0
    case doBindULEBTimesSkippingULEB = 0xc0
    case threaded = 0xd0
    
    var readable: String {
        switch self {
        case .done:
            return "BIND_OPCODE_DONE"
        case .setDylibOrdinalImm:
            return "BIND_OPCODE_SET_DYLIB_ORDINAL_IMM"
        case .setDylibOrdinalULEB:
            return "BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB"
        case .setDylibSpecialImm:
            return "BIND_OPCODE_SET_DYLIB_SPECIAL_IMM"
        case .setSymbolTrailingFlagsImm:
            return "BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM"
        case .setTypeImm:
            return "BIND_OPCODE_SET_TYPE_IMM"
        case .setAddEndSLEB:
            return "BIND_OPCODE_SET_ADDEND_SLEB"
        case .setSegmentAndOffsetULEB:
            return "BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB"
        case .addAddrULEB:
            return "BIND_OPCODE_ADD_ADDR_ULEB"
        case .doBind:
            return "BIND_OPCODE_DO_BIND"
        case .doBindAddAddrULEB:
            return "BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB"
        case .doBindAddAddrImmScaled:
            return "BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED"
        case .doBindULEBTimesSkippingULEB:
            return "BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB"
        case .threaded:
            return "BIND_OPCODE_THREADED"
        }
    }
}

struct BindOperationCode: OperationCodeProtocol {
    
    let bindOperationType: BindOperationType
    let bindImmediateType: BindImmediateType
    
    init(operationCodeValue: UInt8, immediateValue: UInt8) {
        guard let bindOperationType = BindOperationType(rawValue: operationCodeValue) else {
            // unknown opcode. The latest open sourced dyld doesn's recognize this value neither 😄
            // contact the author
            fatalError()
        }
        self.bindOperationType = bindOperationType
        
        switch bindOperationType {
        case .threaded:
            switch immediateValue {
            case 0:
                self.bindImmediateType = .threadedSubSetBindOrdinalTableSizeULEB
            case 1:
                self.bindImmediateType = .threadedSubApple
            default:
                fatalError()
            }
        default:
            self.bindImmediateType = .rawValue(immediateValue)
        }
    }
    
    func operationReadable() -> String {
        return self.bindOperationType.readable
    }
    
    func immediateReadable() -> String {
        return self.bindImmediateType.readable
    }
    
    var numberOfTrailingLEB: Int {
        switch self.bindOperationType {
        case .setDylibOrdinalULEB, .setAddEndSLEB, .setSegmentAndOffsetULEB, .addAddrULEB, .doBindAddAddrULEB:
            return 1
        case .doBindULEBTimesSkippingULEB:
            return 2
        case .threaded:
            switch self.bindImmediateType {
            case .threadedSubSetBindOrdinalTableSizeULEB:
                return 1
            default:
                return 0
            }
        default:
            return 0
        }
    }
    
    var trailingLEBType: LEBType {
        switch self.bindOperationType {
        case .setAddEndSLEB:
            return .signed
        default:
            return .unsigned
        }
    }
    
    func actionDescription() -> String {
        return "//FIXME: " //FIXME:
    }
}
