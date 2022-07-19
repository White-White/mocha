//
//  InstructionComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

import Foundation

// ARMv8 (AArch64) Instruction Encoding
// http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html

class InstructionComponent: MachoComponent {

    let capStoneArchType: CapStoneArchType
    private var instructions: [CapStoneInstruction] = []
    
    init(_ data: Data, title: String, cpuType: CPUType) {
        let capStoneArchType: CapStoneArchType
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
        super.init(data, title: title)
    }
    
    override func initialize() {
        self.instructions = CapStoneHelper.instructions(from: self.data, arch: self.capStoneArchType)
    }
    
    override func createTranslations() -> [Translation] {
        return self.instructions.map { Translation(definition: "Assembly", humanReadable: $0.mnemonic + " " + $0.operand, bytesCount: $0.length, translationType: .code) }
    }
    
}
