//
//  TranslationView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation
import SwiftUI

private struct TranslationItemView: View {
    
    let item: IndexedTranslationItem
    var isSelected: Bool { selectedIndexWrapper.selectedIndexPath == item.indexPath && item.content.explanationStyle.selectable }
    @EnvironmentObject var selectedIndexWrapper: SelectedIndexWrapper
    
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

class SelectedIndexWrapper: ObservableObject {
    @Published var selectedIndexPath: IndexPath = .init(item: .zero, section: .zero)
}

struct TranslationView: View {
    
    let machoComponent: MachoComponent
    let selectedIndexWrapper: SelectedIndexWrapper = SelectedIndexWrapper()
    @Binding var selectedDataRange: Range<Int>?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true)  {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<machoComponent.numberOfTranslationSections(), id: \.self) { section in
                        self.translationSectionView(at: section)
                    }
                }
                .padding(4)
            }
            .background(.white)
            .border(.separator, width: 1)
            .frame(minWidth: 400)
            .onChange(of: machoComponent) { newValue in
                scrollProxy.scrollTo(0, anchor: .top)
            }
        }
    }
    
    func translationSectionView(at section: Int) -> some View {
        return ForEach(indexedTranslationItems(at: section), id: \.indexPath) { item in
            VStack(alignment: .leading, spacing: 0) {
                TranslationItemView(item: item)
                    .environmentObject(self.selectedIndexWrapper)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !item.content.explanationStyle.selectable { return }
                        self.selectedDataRange = item.sourceDataRange
                        self.selectedIndexWrapper.selectedIndexPath = item.indexPath
                    }
                if item.content.hasDivider { Divider() }
            }
        }
    }
    
    func indexedTranslationItems(at section: Int) -> [IndexedTranslationItem] {
        let numberOfTranslationItems = machoComponent.numberOfTranslationItems(at: section)
        return (0..<numberOfTranslationItems).map { itemIndex in
            let indexPath = IndexPath(item: itemIndex, section: section)
            let item = machoComponent.translationItem(at: indexPath)
            return IndexedTranslationItem(item: item, indexPath: indexPath)
        }
    }
    
    init(machoComponent: MachoComponent, sourceDataRangeOfSelecteditem: Binding<Range<Int>?>) {
        self.machoComponent = machoComponent
        _selectedDataRange = sourceDataRangeOfSelecteditem
    }
}

