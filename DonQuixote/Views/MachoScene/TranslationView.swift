//
//  TranslationView.swift
//  DonQuixote
//
//  Created by white on 2023/6/13.
//

import Foundation
import SwiftUI

struct TranslationView: View {
    
    @ObservedObject var machoViewState: MachoViewState
    @ObservedObject var translationStore: TranslationStore
    
    init(machoViewState: MachoViewState) {
        self.machoViewState = machoViewState
        self.translationStore = machoViewState.selectedMachoElement.translationStore
    }
    
    @MainActor
    var body: some View {
        VStack(spacing: 4) {
            
            VStack(alignment: .leading, spacing: 2) {
                Text(self.machoViewState.selectedMachoElement.title + " " + (self.machoViewState.selectedMachoElement.subTitle ?? ""))
                    .bold()
                Divider()
            }
            
            if translationStore.loaded {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        if let instructionSection = machoViewState.selectedMachoElement as? InstructionSection {
                            self.instructionStackView(with: instructionSection.instructionBank)
                        } else {
                            self.defaultTranslationStackView(for: translationStore)
                        }
                    }
                    .onChange(of: machoViewState.selectedTranslation) { newValue in
                        var shouldScroll = true
                        if let instructionSection = machoViewState.selectedMachoElement as? InstructionSection {
                            // when there are too many translations, it takes forever to scroll
                            if instructionSection.instructionBank.numberOfInstructions() > 1024 * 32 {
                                shouldScroll = false
                            }
                        }
                        guard shouldScroll else { return }
                        DispatchQueue.main.async {
                            withAnimation {
                                if let newValue {
                                    scrollViewProxy.scrollTo(newValue.id)
                                }
                            }
                        }
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 0) {
                    VStack(alignment: .center, spacing: 0) {
                        ProgressView()
                        if let loadingProgress = translationStore.loadingProgress {
                            Text(String(format: "Loading... (%.2f %%)", loadingProgress * 100))
                        }
                    }
                }
            }
            
        }
        .id(machoViewState.selectedMachoElement.id)
        .frame(width: 600)
    }
    
    @MainActor
    private func defaultTranslationStackView(for translationStore: TranslationStore) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(translationStore.translationGroups) { translationGroup in
                ForEach(translationGroup.translations) { translation in
                    self.singleTranslationView(for: translation)
                        .onTapGesture {
                            self.machoViewState.onClick(translation: translation, in: translationGroup)
                        }
                }
            }
        }
    }
    
    @MainActor
    private func singleTranslationView(for translation: Translation) -> some View {
        let isSelected = machoViewState.selectedTranslation == translation
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(translation.humanReadable)
                    .font(.system(size: 14))
                    .foregroundColor(Color(nsColor: .textColor))
                if let definition = translation.definition {
                    Text(definition)
                        .font(.system(size: 12))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
                if let extraExplanation = translation.extraHumanReadable {
                    Text(extraExplanation)
                        .foregroundColor(Color(nsColor: .textColor))
                        .font(.system(size: 13))
                }
                if let extraDescription = translation.extraDefinition {
                    Text(extraDescription)
                        .font(.system(size: 12))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
                HStack {
                    Text("\(translation.translationType.description) (\(translation.translationType.bytesCount) bytes)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    if let error = translation.error {
                        Text(error)
                            .font(.system(size: 10))
                            .foregroundColor(Color(nsColor: .white))
                            .background(Color(nsColor: .orange))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            Divider()
        }
        .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
    }
    
}

extension TranslationView {
    
    func instructionStackView(with bank: CapStoneInstructionBank) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(0..<bank.numberOfInstructions(), id: \.self) { index in
                self.singleInstructionTranslationView(for: index, inBank: bank)
            }
        }
    }
    
    
    func singleInstructionTranslationView(for index: Int, inBank bank: CapStoneInstructionBank) -> some View {
        let translation = bank.translation(at: index)
        return self.singleTranslationView(for: translation).onTapGesture {
            self.machoViewState.onClick(translation: translation, in: nil)
        }.id(translation.id)
    }

}
