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
    
    private(set) var instructions: [CapStoneInstruction] = []
    
    var instructionComponentViewModel: InstructionTranslationsViewModel!
    
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
    
    override func asyncInitialize() {
        let disasmResult = CapStoneHelper.instructions(from: self.data, arch: self.capStoneArchType, codeStartAddress: virtualAddress) { progress in
            self.initProgress.updateProgressForInitialize(with: progress)
        }
        if let _ = disasmResult.error {
            //TODO: handle error
        }
        if let instructions = disasmResult.instructions {
            self.instructions = instructions
        }
    }
    
    override func asyncTranslate() {
        var instructionViewModels: [InstructionTranslationViewModel] = []
        var nextStartOffset = self.offsetInMacho
        let maxIndex = self.instructions.count - 1
        for (index, instruction) in self.instructions.enumerated() {
            instructionViewModels.append(InstructionTranslationViewModel(offsetInMacho:nextStartOffset, index: index, instruction: instruction))
            nextStartOffset += instruction.length
            self.initProgress.updateProgressForTranslationInitialize(finishedItems: index, total: maxIndex)
        }
        self.instructionComponentViewModel = InstructionTranslationsViewModel(instructionViewModels)
    }
    
}
