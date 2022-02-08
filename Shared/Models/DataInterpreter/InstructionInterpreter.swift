//
//  InstructionInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

import Foundation

class InstructionInterpreterUnknown: AnonymousInterpreter {
    override var description: String { "Code" }
    override var explanation: String {
        "This part of the macho file is machine code.\nHopper.app is a better tool for this."
    }
}

class InstructionInterpreterIntel: AnonymousInterpreter {
    override var description: String { "Code" }
    override var explanation: String {
        "x86's instructions are of variable length, it'll take too much time to decode.\nHopper.app is a better tool for this."
    }
}

class InstructionInterpreterARM: BaseInterpreter<[CapStoneInstruction]> {
    
    override var payload: [CapStoneInstruction] { fatalError() }
    
    let numberOfInstructions: Int
    let capStoneArchType: CapStoneArchType
    
    override init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource) {
        self.numberOfInstructions = data.count / 4
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
    
    override var numberOfTranslationItems: Int {
        return self.numberOfInstructions
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let instruction = CapStoneHelper.instructions(from: self.data.truncated(from: index * 4, length: 4).raw,
                                                      startVirtualAddress: 0, // FIXME: startVirtualAddress should be a valid, computed value
                                                      arch: capStoneArchType).first!
        return TranslationItem(sourceDataRange: self.data.absoluteRange(index * 4, 4),
                               content: TranslationItemContent(description: "Assembly",
                                                               explanation: instruction.mnemonic + "    " + instruction.operand))
    }
}

// ARMv8 (AArch64) Instruction Encoding
// http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html
