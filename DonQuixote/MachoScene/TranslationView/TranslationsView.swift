//
//  TranslationsView.swift
//  mocha (macOS)
//
//  Created by white on 2022/12/9.
//

import Foundation
import SwiftUI


//private var translationGroups: [TranslationGroup] {
//    get async {
//        await self.translationContainer.loadTranslationsIfNeeded(from: self)
//    }
//}
//
//func numberOfTranslationGroups() async -> Int {
//    return await self.translationGroups.count
//}
//
//func numberOfTranslations(in groupIndex: Int) async -> Int {
//    return await self.translationGroups[groupIndex].count
//}
//
//func translation(at indexPath: IndexPath) async -> BaseTranslation {
//    return await self.translationGroups[indexPath.section][indexPath.item]
//}

//@MainActor
//class TranslationFetcher: ObservableObject {
//
//    @Published var translationCounts: [Int] = []
//
//    var machoBaseElement: MachoBaseElement?
//
//    func update(with machoBaseElement: MachoBaseElement) async {
//        self.machoBaseElement = machoBaseElement
//        var translationCounts: [Int] = []
//        for groupIndex in 0..<(await machoBaseElement.numberOfTranslationGroups()) {
//            translationCounts.append(await machoBaseElement.numberOfTranslations(in: groupIndex))
//        }
//        self.translationCounts = translationCounts
//    }
//
//    func translation(at indexPath: IndexPath) async -> BaseTranslation {
//        return await self.machoBaseElement!.translation(at: indexPath)
//    }
//
//}

struct TranslationsView: View {
    
    static let minWidth: CGFloat = 300
    
    @Binding var selectedDataRange: Range<UInt64>?
    @State var selectedIndexPath: IndexPath? = nil
    
    let machoBaseElement: MachoBaseElement
    @ObservedObject var translationContainer: TranslationsContainer
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
                        ForEach(0..<translationContainer.translationGroups.count, id: \.self) { groupIndex in
                            LazyVStack(spacing: 0) {
                                ForEach(0..<translationContainer.translationGroups[groupIndex].count, id: \.self) { itemIndex in
                                    self.translationView(for: IndexPath(item: itemIndex, section: groupIndex))
                                }
                            }
                        }
                    }
                }
//                .onChange(of: machoBaseElement) { newValue in
//                    self.selectedIndexPath = nil
//                    self.selectedDataRange = nil
//                    scrollViewProxy.scrollTo(0, anchor: .top)
//                }
            }
        }
    }
    
    func translationView(for indexPath: IndexPath) -> some View {
        let translation = translationContainer.translationGroups[indexPath.section][indexPath.item]
        return SingleTranslationView(translation: translation, isSelected: selectedIndexPath == indexPath)
            .onTapGesture {
                self.selectedIndexPath = indexPath
                self.selectedDataRange = translation.dataRangeInMacho!
            }
    }
    
    init(machoBaseElement: MachoBaseElement, selectedDataRange: Binding<Range<UInt64>?>) {
        self.machoBaseElement = machoBaseElement
        self.translationContainer = machoBaseElement.translationContainer
        self.initProgress = machoBaseElement.initProgress
        _selectedDataRange = selectedDataRange
    }
    
}
