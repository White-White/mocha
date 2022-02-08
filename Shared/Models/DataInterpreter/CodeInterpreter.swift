//
//  CodeInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

import Foundation

struct Instruction {
    let mnemonic: String
    let operand: String
    let startOffset: Int
    let commandSize: Int
}

class CodeInterpreter: BaseInterpreter<[Instruction]> {
    
    override var shouldPreload: Bool { true }
    
    override init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource) {
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }
    
    override func generatePayload() -> [Instruction] {
        
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
        
        let capStoneInstructions = CapStoneHelper.instructions(from: self.data.raw, startVirtualAddress: 0, arch: capStoneArchType)
        return capStoneInstructions.map { Instruction(mnemonic: $0.mnemonic, operand: $0.operand, startOffset: $0.startOffset, commandSize: $0.commandSize) }
    }
    
    override var numberOfTranslationItems: Int {
        return self.payload.count
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let instruction = self.payload[index]
        return TranslationItem(sourceDataRange: self.data.absoluteRange(instruction.startOffset, instruction.commandSize),
                               content: TranslationItemContent(description: "Assembly",
                                                               explanation: instruction.mnemonic + "    " + instruction.operand))
    }
}

// ARMv8 (AArch64) Instruction Encoding
// http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html
