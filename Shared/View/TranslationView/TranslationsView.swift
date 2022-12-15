//
//  TranslationsView.swift
//  mocha (macOS)
//
//  Created by white on 2022/12/9.
//

import Foundation
import SwiftUI

struct TranslationsView: View {
    
    static let minWidth: CGFloat = 300
    
    let machoComponent: MachoComponent
    @Binding var selectedDataRange: Range<UInt64>?
    @State var selectedIndexPath: IndexPath? = nil
    @ObservedObject var initProgress: InitProgress
    
    var body: some View {
        if !initProgress.isDone {
            HStack {
                ProgressView()
            }.frame(minWidth: TranslationsView.minWidth)
        } else {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<machoComponent.numberOfTranslationGroups(), id: \.self) { groupIndex in
                            LazyVStack(spacing: 0) {
                                ForEach(0..<machoComponent.numberOfTranslations(in: groupIndex), id: \.self) { itemIndex in
                                    self.translationView(for: IndexPath(item: itemIndex, section: groupIndex))
                                }
                            }
                        }
                    }
                }
                .onChange(of: machoComponent) { newValue in
                    self.selectedIndexPath = nil
                    self.selectedDataRange = nil
                    scrollViewProxy.scrollTo(0, anchor: .top)
                }
            }
        }
    }
    
    func translationView(for indexPath: IndexPath) -> some View {
        let translation = machoComponent.translation(at: indexPath)
        return SingleTranslationView(translation: translation, isSelected: selectedIndexPath == indexPath)
            .onTapGesture {
                self.selectedIndexPath = indexPath
                self.selectedDataRange = translation.dataRangeInMacho!
            }
    }
    
    init(machoComponent: MachoComponent, selectedDataRange: Binding<Range<UInt64>?>) {
        self.machoComponent = machoComponent
        self.initProgress = machoComponent.initProgress
        _selectedDataRange = selectedDataRange
    }
    
}
