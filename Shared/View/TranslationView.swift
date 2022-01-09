//
//  TranslationView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation
import SwiftUI

class IdentifiableTranslationItem: ObservableObject {
    let item: TranslationItem
    let indexPath: IndexPath
    @Published var isSelected: Bool
    init(item: TranslationItem, indexPath: IndexPath, isSelected: Bool = false) {
        self.item = item
        self.indexPath = indexPath
        self.isSelected = isSelected
    }
}

private struct TranslationItemView: View {
    
    @ObservedObject var identifiableItem: IdentifiableTranslationItem
    var item: TranslationItem { identifiableItem.item }
    var isSelected: Bool { identifiableItem.isSelected }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let description = item.content.description {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }
            Text(item.content.explanation)
                .foregroundColor(isSelected ? .white : .black)
                .font(item.content.monoSpaced ? .system(size: 12).monospaced() : .system(size: 14))
                .background(isSelected ? Theme.selected : .white)
            if let extraExplanation = item.content.extraExplanation {
                Text(extraExplanation)
                    .foregroundColor(.gray)
                    .font(item.content.monoSpaced ? .system(size: 12).monospaced() : .system(size: 14))
            }
        }
        .padding(.leading, 4)
        .padding(.bottom, 6)
        .padding(.top, 6)
    }
}

class SelectedItemWrapper {
    var selectedItem: IdentifiableTranslationItem
    init(_ t: IdentifiableTranslationItem) { self.selectedItem = t }
}

struct TranslationView: View {
    
    let machoComponent: MachoComponent
    let selectedItemWrapper: SelectedItemWrapper
    @Binding var sourceDataRangeOfSelecteditem: Range<Int>?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true)  {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<numberOfSection(), id: \.self) { section in
                        if let sectionTitle = machoComponent.sectionTile(of: section) {
                            VStack(alignment: .center, spacing: 0) {
                                Text(sectionTitle)
                                    .font(.system(size: 15).bold())
                                    .padding(.leading, 4)
                                    .padding(.top, 6)
                                    .padding(.bottom, 4)
                                Divider()
                            }
                        }
                        ForEach(items(at: section), id: \.indexPath) { identifiableItem in
                            VStack(alignment: .leading, spacing: 0) {
                                TranslationItemView(identifiableItem: identifiableItem)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        sourceDataRangeOfSelecteditem = identifiableItem.item.sourceDataRange
                                        identifiableItem.isSelected.toggle()
                                        self.selectedItemWrapper.selectedItem.isSelected.toggle()
                                        self.selectedItemWrapper.selectedItem = identifiableItem
                                    }
                                Divider()
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
                scrollProxy.scrollTo(0, anchor: .top)
            }
        }
        .onChange(of: machoComponent) { newValue in
            let firstItem = IdentifiableTranslationItem(item: newValue.firstTransItem!,
                                                        indexPath: IndexPath(item: .zero, section: .zero),
                                                        isSelected: true)
            self.selectedItemWrapper.selectedItem = firstItem
        }
    }
    
    func numberOfSection() -> Int {
        return machoComponent.numberOfTranslationSections()
    }
    
    func items(at section: Int) -> [IdentifiableTranslationItem] {
        return machoComponent.translationItems(at: section).enumerated().map {
            let indexPath = IndexPath(item: $0.offset, section: section)
            if indexPath == self.selectedItemWrapper.selectedItem.indexPath {
                return self.selectedItemWrapper.selectedItem
            } else {
                return IdentifiableTranslationItem(item: $0.element, indexPath: indexPath)
            }
        }
    }
    
    init(machoComponent: MachoComponent, sourceDataRangeOfSelecteditem: Binding<Range<Int>?>) {
        self.machoComponent = machoComponent
        _sourceDataRangeOfSelecteditem = sourceDataRangeOfSelecteditem
        
        let firstItem = IdentifiableTranslationItem(item: machoComponent.firstTransItem!,
                                                    indexPath: IndexPath(item: .zero, section: .zero),
                                                    isSelected: true)
        self.selectedItemWrapper = SelectedItemWrapper(firstItem)
    }
}
    
