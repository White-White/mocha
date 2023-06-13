//
//  TranslationView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/23.
//

import SwiftUI

struct SingleTranslationView: View {
    
    let translation: Translation
    var isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                if let commonTranslation = translation as? Translation {
                    Text(commonTranslation.humanReadable)
                        .font(.system(size: 14))
                        .foregroundColor(Color(nsColor: .textColor))
                    if let definition = commonTranslation.definition {
                        Text(definition)
                            .font(.system(size: 12))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                    if let extraExplanation = commonTranslation.extraHumanReadable {
                        Text(extraExplanation)
                            .foregroundColor(Color(nsColor: .textColor))
                            .font(.system(size: 13))
                    }
                    if let extraDescription = commonTranslation.extraDefinition {
                        Text(extraDescription)
                            .font(.system(size: 12))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    }
                    HStack {
                        Text("\(commonTranslation.translationType.description) (\(commonTranslation.translationType.bytesCount) bytes)")
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
//                else if let instructionTranslation = translation as? InstructionTranslation {
//                    HStack(spacing: 0) {
//                        Text(instructionTranslation.capstoneInstruction.mnemonic)
//                            .font(.system(size: 14, weight: .bold).monospaced())
//                            .frame(width: 60, alignment: .leading)
//                        Text(instructionTranslation.capstoneInstruction.operand)
//                            .font(.system(size: 14).monospaced())
//                    }
//                }
                else {
                    fatalError()
                }
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            Divider()
        }
        .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
    }
    
}
