//
//  InstructionComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

import Foundation

class InstructionComponent: MachoLazyComponent<[CapStoneInstruction]> {

    override var shouldPreload: Bool { true }
    let capStoneArchType: CapStoneArchType
    
    override init(_ dataSlice: DataSlice, macho: Macho, is64Bit: Bool, title: String, subTitle: String?) {
        let capStoneArchType: CapStoneArchType
        let cpuType = macho.cpuType
        switch cpuType {
        case .x86:
            capStoneArchType = .I386
        case .x86_64:
            capStoneArchType = .X8664
        case .arm:
            capStoneArchType = .ARM
        case .arm64:
            capStoneArchType = .ARM64
        case .arm64_32:
            fallthrough
        case .unknown(_):
            fatalError() /* unknown code */
        }
        self.capStoneArchType = capStoneArchType
        super.init(dataSlice, macho: macho, is64Bit: is64Bit, title: title, subTitle: subTitle)
    }
    
    override func generatePayload() -> [CapStoneInstruction] {
        return CapStoneHelper.instructions(from: dataSlice.raw, arch: capStoneArchType)
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.count
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let instruction = self.payload[indexPath.section]
        return TranslationItem(sourceDataRange: self.dataSlice.absoluteRange(instruction.startOffset, instruction.length),
                               content: TranslationItemContent(description: "Assembly",
                                                               explanation: instruction.mnemonic + "    " + instruction.operand))
    }
}

// ARMv8 (AArch64) Instruction Encoding
// http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html
