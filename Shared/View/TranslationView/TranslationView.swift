//
//  TranslationView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/23.
//

import SwiftUI

class TranslationViewModel: ObservableObject, Equatable, Identifiable {
    
    static func == (lhs: TranslationViewModel, rhs: TranslationViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID()
    
    @Published var isSelected: Bool = false
    let range: Range<UInt64>
    let translation: Translation
    let index: Int
    
    init(_ translation: Translation, range: Range<UInt64>, index: Int) {
        self.translation = translation
        self.range =  range
        self.index = index
    }
    
}

struct TranslationView: View {
    
    @ObservedObject var viewModel: TranslationViewModel
    var translation: Translation { viewModel.translation }
    var isSelected: Bool { viewModel.isSelected }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                Text("Length: \(translation.bytesCount) bytes | Data Type: \(translation.translationType.description)")
                    .font(.system(size: 10))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            Divider()
        }
        .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
    }
    
}
