//
//  TranslationItemView.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/30.
//

import SwiftUI

class TranslationItemViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let item: TranslationItem
    @Published var isSelected: Bool = false
    
    init(_ i: TranslationItem) {
        self.item = i
    }
}

struct TranslationItemView: View {
    
    @ObservedObject var viewModel: TranslationItemViewModel
    var item: TranslationItem { viewModel.item }
    var isSelected: Bool { viewModel.isSelected }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let description = item.content.description {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }
            Text(item.content.explanation)
                .foregroundColor(isSelected ? .white : item.content.explanationStyle.fontColor)
                .font(item.content.monoSpaced ? .system(size: 12).monospaced() : .system(size: 14))
                .background(isSelected ? Theme.selected : .white)
            if let extraDescription = item.content.extraDescription {
                Text(extraDescription)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                    .padding(.bottom, 2)
            }
            if let extraExplanation = item.content.extraExplanation {
                Text(extraExplanation)
                    .foregroundColor(.gray)
                    .font(item.content.monoSpaced ? .system(size: 12).monospaced() : .system(size: 14))
            }
        }
        .padding(.leading, 4)
        .padding(.bottom, 3)
        .padding(.top, 3)
    }
}
