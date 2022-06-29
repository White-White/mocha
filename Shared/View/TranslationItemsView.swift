//
//  TranslationView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation
import SwiftUI

class TranslationItemViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let item: TranslationItem
    @Published var isSelected: Bool = false
    init(_ i: TranslationItem) { self.item = i }
}

private struct TranslationItemView: View {
    
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

struct TranslationItemsView: View {
    
    static let numberOfSectionsInPage = 128
    
    @Binding var machoComponent: MachoComponent
    
    @State var lastPage: Int?
    @Binding var currentPage: Int
    @Binding var highLightedDataRange: Range<Int>?
    
    @State var selectedViewModel: TranslationItemViewModel?
    @State var translationItemViewModels: [[TranslationItemViewModel]]
    
    init(machoComponent: Binding<MachoComponent>, currentPage: Binding<Int>, highLightedDataRange: Binding<Range<Int>?>) {
        _machoComponent = machoComponent
        _lastPage = State(initialValue: nil)
        _currentPage = currentPage
        _highLightedDataRange = highLightedDataRange
        let viewModels = TranslationItemsView.viewModels(from: machoComponent.wrappedValue, at: currentPage.wrappedValue)
        _translationItemViewModels = State(initialValue: viewModels)
        _selectedViewModel = State(initialValue: viewModels.first?.first)
        _selectedViewModel.wrappedValue?.isSelected = true
    }
    
    static func viewModels(from machoComponent: MachoComponent, at currentPage: Int) -> [[TranslationItemViewModel]] {
        var translationItemViewModels: [[TranslationItemViewModel]] = []
        let sectionStartIndex = min(currentPage * TranslationItemsView.numberOfSectionsInPage, machoComponent.numberOfTranslationSections() - 1)
        let sectionEndIndex = min(sectionStartIndex + TranslationItemsView.numberOfSectionsInPage, machoComponent.numberOfTranslationSections())
        for sectionIndex in sectionStartIndex..<sectionEndIndex {
            let numberOfItems = machoComponent.numberOfTranslationItems(at: sectionIndex)
            let translationItems = (0..<numberOfItems).map { machoComponent.translationItem(at: IndexPath(item: $0, section: sectionIndex)) }
            let viewModels = translationItems.map { TranslationItemViewModel($0) }
            translationItemViewModels.append(viewModels)
        }
        return translationItemViewModels
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true)  {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(translationItemViewModels.indices, id: \.self) { index in
                        ForEach(translationItemViewModels[index]) { viewModel in
                            VStack(alignment: .leading, spacing: 0) {
                                TranslationItemView(viewModel: viewModel)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if !viewModel.item.content.explanationStyle.selectable { return }
                                        if viewModel.id == self.selectedViewModel?.id { return }
                                        
                                        self.selectedViewModel?.isSelected = false
                                        self.selectedViewModel = viewModel
                                        self.selectedViewModel?.isSelected = true
                                        self.highLightedDataRange = self.selectedViewModel?.item.sourceDataRange
                                    }
                                if viewModel.item.content.hasDivider { Divider() }
                            }
                        }
                    }
                }
                .padding(4)
            }
            .background(.white)
            .border(.separator, width: 1)
            .frame(minWidth: 400)
            .onChange(of: machoComponent) { newValue in
                self.currentPage = 0
                self.translationItemViewModels = TranslationItemsView.viewModels(from: newValue, at: self.currentPage)
                self.selectedViewModel = self.translationItemViewModels.first?.first
                self.selectedViewModel?.isSelected = true
                self.highLightedDataRange = self.selectedViewModel?.item.sourceDataRange
                
                DispatchQueue.main.async {
                    if let id = self.selectedViewModel?.id {
                        scrollProxy.scrollTo(id)
                    }
                }
            }
            .onChange(of: currentPage) { newValue in
                self.translationItemViewModels = TranslationItemsView.viewModels(from: machoComponent, at: newValue)
                if let lastPage = lastPage, lastPage > newValue {
                    self.selectedViewModel = self.translationItemViewModels.last?.last
                    self.selectedViewModel?.isSelected = true
                } else {
                    scrollProxy.scrollTo(0, anchor: .top)
                    self.selectedViewModel = self.translationItemViewModels.first?.first
                    self.selectedViewModel?.isSelected = true
                }
                self.lastPage = newValue
                self.highLightedDataRange = self.selectedViewModel?.item.sourceDataRange
                
                DispatchQueue.main.async {
                    if let id = self.selectedViewModel?.id {
                        scrollProxy.scrollTo(id)
                    }
                }
            }
        }
    }
}

