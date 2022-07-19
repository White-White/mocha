//
//  TranslationGroupsView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import SwiftUI

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
                Text("\(translation.definition)" + " | " + "\(translation.bytesCount) bytes" + " | " + translation.translationType.description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                if let extraExplanation = translation.extraHumanReadable {
                    Text(extraExplanation)
                        .foregroundColor(Color(nsColor: .textColor))
                        .font(.system(size: 14))
                }
                if let extraDescription = translation.extraDefinition {
                    Text(extraDescription)
                        .font(.system(size: 12))
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                        .padding(.top, 2)
                        .padding(.bottom, 2)
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 0))
            Divider()
        }
        .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
    }
    
}

struct TranslationGroupView: View {
    
    let translationGroupViewModel: TranslationGroupViewModel
    @Binding var selectedRange: Range<UInt64>?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(translationGroupViewModel.translationViewModels, id: \.range) { viewModel in
                        TranslationView(viewModel: viewModel)
                            .onTapGesture {
                                if viewModel.isSelected { return }
                                self.selectedRange = viewModel.range
                                self.translationGroupViewModel.selectedIndex = viewModel.indexInGroup
                            }
                    }
                }
            }
            .background(.white)
            .frame(minWidth: 500)
            .onChange(of: translationGroupViewModel) { newValue in
                if let firstViewModel = (newValue.translationViewModels.first { $0.isSelected }) {
                    scrollProxy.scrollTo(firstViewModel.range)
                }
            }
        }
    }
    
    init(translationGroupViewModel: TranslationGroupViewModel, selectedRange: Binding<Range<UInt64>?>) {
        self.translationGroupViewModel = translationGroupViewModel
        _selectedRange = selectedRange
    }
}

