//
//  InstructionContentView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/23.
//

import SwiftUI

class InstructionTranslationViewModel: ObservableObject, Identifiable, Equatable {
    
    @Published var isSelected: Bool = false
    var id: Int { offsetInMacho }
    let offsetInMacho: Int
    let length: Int
    let index: Int
    let mnemonicSpace: String
    let operand: String
    
    var dataRange: Range<UInt64> {
        UInt64(offsetInMacho)..<UInt64(offsetInMacho+length)
    }
    
    init(offsetInMacho: Int, index: Int, instruction: CapStoneInstruction) {
        self.index = index
        self.offsetInMacho = offsetInMacho
        self.length = instruction.length
        
        let mnemonicSpaceLength = 10
        let mnemonic = instruction.mnemonic
        let space = String([Character].init(repeating: " ", count: max(0, mnemonicSpaceLength - mnemonic.count)))
        self.mnemonicSpace = mnemonic + space
        self.operand = instruction.operand
    }
    
    static func == (lhs: InstructionTranslationViewModel, rhs: InstructionTranslationViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
}

class InstructionTranslationsViewModel {
    
    let instructionViewModels: [InstructionTranslationViewModel]
    
    var selectedIndex: Int = 0 {
        willSet {
            instructionViewModels[selectedIndex].isSelected = false
        }
        didSet {
            instructionViewModels[selectedIndex].isSelected = true
        }
    }
    
    var selectedInstructionViewModel: InstructionTranslationViewModel {
        return self.instructionViewModels[self.selectedIndex]
    }
    
    init(_ instructionViewModels: [InstructionTranslationViewModel]) {
        self.instructionViewModels = instructionViewModels
        self.selectedInstructionViewModel.isSelected = true
    }
    
}

struct InstructionTranslationView: View {
    
    @ObservedObject var viewModel: InstructionTranslationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(viewModel.mnemonicSpace)
                    .font(.system(size: 14, weight: .bold).monospaced())
                Text(viewModel.operand)
                    .font(.system(size: 14).monospaced())
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 0))
            Divider()
        }
        .background(viewModel.isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
    }
    
}

struct InstructionTranslationsView: View {
    
    let instructionComponentViewModel: InstructionTranslationsViewModel
    let selectedDataRangeWrapper: ObserableValueWrapper<Range<UInt64>?>
    
    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(instructionComponentViewModel.instructionViewModels) { instructionViewModel in
                        InstructionTranslationView(viewModel: instructionViewModel)
                            .onTapGesture {
                                guard !instructionViewModel.isSelected else { return }
                                self.instructionComponentViewModel.selectedIndex = instructionViewModel.index
                                self.selectedDataRangeWrapper.value = self.instructionComponentViewModel.selectedInstructionViewModel.dataRange
                            }
                    }
                }
            }
        }
    }
    
    init(_ instructionComponentViewModel: InstructionTranslationsViewModel, machoViewState: MachoViewState) {
        self.instructionComponentViewModel = instructionComponentViewModel
        self.selectedDataRangeWrapper = machoViewState.selectedDataRangeWrapper
        
        instructionComponentViewModel.selectedIndex = 0
        machoViewState.selectedDataRangeWrapper.value = instructionComponentViewModel.selectedInstructionViewModel.dataRange
    }
    
}
