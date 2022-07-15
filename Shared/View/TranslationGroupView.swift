//
//  TranslationGroupsView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import SwiftUI

class TranslationViewModel: ObservableObject, Equatable {
    
    static func == (lhs: TranslationViewModel, rhs: TranslationViewModel) -> Bool {
        return lhs.range == rhs.range
    }
    
    let range: Range<UInt64>
    @Published var isSelected: Bool
    let item: Translation
    let indexInGroup: Int
    
    init(_ i: Translation, range: Range<UInt64>, indexInGroup: Int, isSelected: Bool) {
        self.item = i
        self.range =  range
        self.isSelected = isSelected
        self.indexInGroup = indexInGroup
    }
    
}

struct TranslationView: View {
    
    @ObservedObject var viewModel: TranslationViewModel
    var item: Translation { viewModel.item }
    var isSelected: Bool { viewModel.isSelected }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if let description = item.description {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                }
                Text(item.explanation)
                    .font(item.monoSpaced ? .system(size: 12).monospaced() : .system(size: 14))
                    .background(isSelected ? Color(nsColor: .selectedTextBackgroundColor) : .white)
                if let extraDescription = item.extraDescription {
                    Text(extraDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                        .padding(.bottom, 2)
                }
                if let extraExplanation = item.extraExplanation {
                    Text(extraExplanation)
                        .foregroundColor(.gray)
                        .font(item.monoSpaced ? .system(size: 12).monospaced() : .system(size: 14))
                }
            }
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            Divider()
        }
    }
    
}

struct TranslationGroupView: View {
    
    let translationGroup: TranslationGroup
    @Binding var selectedRange: Range<UInt64>
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(translationGroup.translationViewModels, id: \.range) { viewModel in
                        TranslationView(viewModel: viewModel)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.selectedRange = viewModel.range
                                self.translationGroup.selectedIndex = viewModel.indexInGroup
                            }
                    }
                }
            }
            .background(.white)
            .border(.separator, width: 1)
            .frame(minWidth: 500)
            .onChange(of: translationGroup) { newValue in
                if let firstViewModel = (newValue.translationViewModels.first { $0.isSelected }) {
                    scrollProxy.scrollTo(firstViewModel.range)
                    self.selectedRange = firstViewModel.range
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
    }
    
    init(translationGroup: TranslationGroup, selectedRange: Binding<Range<UInt64>>) {
        self.translationGroup = translationGroup
        _selectedRange = selectedRange
    }
}

