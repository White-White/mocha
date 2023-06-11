//
//  MachoSection.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import Foundation

class MachoSection: MachoBaseElement {
    
    static func createSection(allCStrngSections: [CStringSection],
                              indirectSymbolTable: IndirectSymbolTable?,
                              machoData: Data,
                              machoHeader: MachoHeader,
                              sectionHeader: SectionHeader) -> MachoBaseElement {
        
        let is64Bit = machoHeader.is64Bit
        let title = sectionHeader.segment + "," + sectionHeader.section
        
        // recognize section by section type
        switch sectionHeader.sectionType {
        case .S_ZEROFILL, .S_THREAD_LOCAL_ZEROFILL, .S_GB_ZEROFILL:
            // ref: https://lists.llvm.org/pipermail/llvm-commits/Week-of-Mon-20151207/319108.html
            /* code snipet from llvm
             inline bool isZeroFillSection(SectionType T) {
             return (T == llvm::MachO::S_ZEROFILL ||
             T == llvm::MachO::S_THREAD_LOCAL_ZEROFILL);
             }
             */
            return ZeroFilledSection(runtimeSize: Int(sectionHeader.size), title: title)
            
        case .S_CSTRING_LITERALS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return CStringSection(virtualAddress: sectionHeader.addr, data: data, title: title)
        case .S_LITERAL_POINTERS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return LiteralPointerComponent(allCStringSections: allCStrngSections, data: data, is64Bit: is64Bit, title: title)
        case .S_LAZY_SYMBOL_POINTERS, .S_NON_LAZY_SYMBOL_POINTERS, .S_LAZY_DYLIB_SYMBOL_POINTERS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return SymbolPointerComponent(indirectSymbolTable: indirectSymbolTable, sectionHeader: sectionHeader, data: data, is64Bit: is64Bit, title: title)
        default:
            break
        }
        
        // recognize section by section attributes
        if sectionHeader.sectionAttributes.hasAttribute(.S_ATTR_PURE_INSTRUCTIONS) {
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return InstructionSection(data, title: title, cpuType: machoHeader.cpuType, virtualAddress: sectionHeader.addr)
        }
        
        // recognize section by section name
        let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size), allowZeroLength: true)
        switch sectionHeader.segment {
        case "__TEXT":
            switch sectionHeader.section {
            case "__const":
                return TextConstSection(data, title: title, subTitle: nil)
            case "__ustring":
                return UStringSection(data: data, title: title, subTitle: nil)
            case "__swift5_reflstr":
                // https://knight.sc/reverse%20engineering/2019/07/17/swift-metadata.html
                // a great article on introducing swift metadata sections
                return CStringSection(virtualAddress: sectionHeader.addr, data: data, title: title)
            case "__swift5_protos":
                return SwiftMetadataSection<ProtocolDescriptor>(data, title: title, virtualAddress: sectionHeader.addr)
            case "__swift5_proto":
                return SwiftMetadataSection<ProtocolConformanceDescriptor>(data, title: title, virtualAddress: sectionHeader.addr)
            case "__swift5_types":
                fallthrough
            default:
                return UnknownSection(data, title: title, subTitle: nil)
            }
        default:
            return UnknownSection(data, title: title, subTitle: nil)
        }
    }

}
