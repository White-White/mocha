//
//  InstructionComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

import Foundation
import SwiftUI

// ARMv8 (AArch64) Instruction Encoding
// http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html

class InstructionComponent: MachoComponent {

    let capStoneArchType: CapStoneArchType
    let virtualAddress: UInt64
    var instructionBank: CapStoneInstructionBank!
    
    init(_ data: Data, title: String, cpuType: CPUType, virtualAddress: UInt64) {
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
        self.virtualAddress = virtualAddress
        super.init(data, title: title)
    }
    
    override func runInitializing() {
        let instructionBank = CapStoneHelper.instructions(from: self.data, arch: self.capStoneArchType, codeStartAddress: virtualAddress) { progress in
            self.initProgress.updateProgressForInitialize(with: progress)
        }
        if let _ = instructionBank.error {
            //TODO: handle error
        }
        self.instructionBank = instructionBank
    }
    
    override func runTranslating() -> [TranslationGroup] {
        return []
    }
    
    override func numberOfTranslations(in section: Int) -> Int {
        return Int(self.instructionBank.numberOfInstructions())
    }
    
    override func numberOfTranslationGroups() -> Int {
        return 1
    }
    
    override func translation(at indexPath: IndexPath) -> BaseTranslation {
        let instruction = self.instructionBank.instruction(at: UInt(indexPath.item))
        return InstructionTranslation(capstoneInstruction: instruction)
    }
    
}
