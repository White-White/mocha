//
//  InstructionInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

import Foundation

class InstructionInterpreter: BaseInterpreter<[CapStoneInstruction]> {

    override var shouldPreload: Bool { true }
    let capStoneArchType: CapStoneArchType
    
    override init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource) {
        let capStoneArchType: CapStoneArchType
        let cpuType = machoSearchSource.cpuType
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
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }
    
    override func generatePayload() -> [CapStoneInstruction] {
        return CapStoneHelper.instructions(from: self.data.raw, arch: capStoneArchType)
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.count
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        let instruction = self.payload[indexPath.section]
        return TranslationItem(sourceDataRange: self.data.absoluteRange(instruction.startOffset, instruction.length),
                               content: TranslationItemContent(description: "Assembly",
                                                               explanation: instruction.mnemonic + "    " + instruction.operand))
    }
}

// ARMv8 (AArch64) Instruction Encoding
// http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html
