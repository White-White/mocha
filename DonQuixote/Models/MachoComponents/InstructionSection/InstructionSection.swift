//
//  InstructionSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

import Foundation
import SwiftUI

// ARMv8 (AArch64) Instruction Encoding
// http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html

extension CapStoneInstructionBank {
    
    func translation(at index: Int) -> Translation {
        let capInstruction = self.instruction(at: index)
        var translation = Translation(definition: nil, humanReadable: capInstruction.mnemonic + capInstruction.operand, translationType: .code(Int(capInstruction.size)))
        translation.rangeInMacho = capInstruction.startAddrInMacho..<(capInstruction.startAddrInMacho + UInt64(capInstruction.size))
        return translation
    }
    
}

class InstructionSection: MachoBaseElement {

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
        super.init(data, title: title, subTitle: nil)
    }
    
    override func loadTranslations() async {
        let instructionBank = CapStoneHelper.instructions(from: self.data, arch: self.capStoneArchType, codeStartAddress: virtualAddress) { progress in
            Task { @MainActor in
                self.translationStore.update(loadingProgress: progress)
            }
        }
        if let _ = instructionBank.error {
            //TODO: handle error
        }
        
        instructionBank.codeStartAddr = self.virtualAddress
        instructionBank.instructionSectionOffsetInMacho = UInt64(self.offsetInMacho)
        
        self.instructionBank = instructionBank
    }
    
    override func searchForTranslation(with targetDataIndex: UInt64) async -> MachoBaseElement.TranslationSearchResult? {
        await self.translationStore.suspendUntilLoaded(callerTag: "Translation search")
        let searchedIndex = self.instructionBank.searchIndexForInstruction(with: targetDataIndex)
        guard searchedIndex >= 0 else { return nil }
        
        return TranslationSearchResult(translationGroup: nil, translation: self.instructionBank.translation(at: searchedIndex))
    }
    
}
