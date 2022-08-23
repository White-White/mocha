//
//  TranslationGroupsView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import SwiftUI

struct TranslationsViewContainer: View {
    
    let machoViewState: MachoViewState
    @ObservedObject var selectedMachoComponentWrapper: ObserableValueWrapper<MachoComponent>
    @State var machoComponent: MachoComponent
    @State var showBlankPage: Bool = false
    
    var body: some View {
        HStack {
            if self.showBlankPage {
                Color.white
            } else {
                if let simpleTranslationsComponent = machoComponent as? MachoComponentWithTranslations {
                    SimpleTranslationsView(viewModel: simpleTranslationsComponent.simpleTranslationsViewModel, machoViewState: self.machoViewState)
                } else if let instructionComponent = machoComponent as? InstructionComponent {
                    InstructionTranslationsView(instructionComponent.instructionComponentViewModel, machoViewState: self.machoViewState)
                } else if let modeledTranslationComponent = machoComponent as? ModeledTranslationComponent {
                    ModeledTranslationsView(viewModel: modeledTranslationComponent.modeledTranslationsViewModel, machoViewState: self.machoViewState)
                } else {
                    fatalError()
                }
            }
        }
        .onChange(of: selectedMachoComponentWrapper.value, perform: { newValue in
            withAnimation {
                self.showBlankPage = true
                DispatchQueue.main.async {
                    self.machoComponent = newValue
                    self.showBlankPage = false
                }
            }
        })
        .background(.white)
        .frame(minWidth: 500)
    }
    
    init(machoViewState: MachoViewState) {
        self.machoViewState = machoViewState
        self.selectedMachoComponentWrapper = machoViewState.selectedMachoComponentWrapper
        self.machoComponent = machoViewState.selectedMachoComponentWrapper.value
    }
    
}

