//
//  TranslationView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/28.
//

import Foundation
import SwiftUI

private struct TranslationItemView: View {
    
    let item: TranslationItem
    let index: Int
    var isSelected: Bool { selectedIndexWrapper.selectedIndex == index }
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
        .padding(.bottom, 3)
        .padding(.top, 3)
    }
}

class SelectedIndexWrapper: ObservableObject {
    @Published var selectedIndex: Int = 0
}

struct TranslationView: View {
    
    let machoComponent: MachoComponent
    let selectedIndexWrapper: SelectedIndexWrapper = SelectedIndexWrapper()
    @Binding var selectedDataRange: Range<Int>?
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true)  {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<machoComponent.numberOfTranslationItems, id: \.self) { index in
                        self.translationView(at: index)
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
    
    func translationView(at index: Int) -> some View {
        let item = machoComponent.translationItem(at: index)
        return VStack(alignment: .leading, spacing: 0) {
            TranslationItemView(item: item, index: index)
                .environmentObject(self.selectedIndexWrapper)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.selectedDataRange = item.sourceDataRange
                    self.selectedIndexWrapper.selectedIndex = index
                }
            if item.hasDivider {
                Divider()
            }
        }
    }
    
    init(machoComponent: MachoComponent, sourceDataRangeOfSelecteditem: Binding<Range<Int>?>) {
        self.machoComponent = machoComponent
        _selectedDataRange = sourceDataRangeOfSelecteditem
    }
}
    
