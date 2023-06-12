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
    
    @Binding var selectedTranslation: Translation?
    @ObservedObject var translationContainer: TranslationStore
    
    var body: some View {
//        if !initProgress.isDone {
//            HStack {
//                ProgressView()
//            }.frame(minWidth: TranslationsView.minWidth)
//        } else {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<translationContainer.translationGroups.count, id: \.self) { groupIndex in
                            ForEach(translationContainer.translationGroups[groupIndex]) { translation in
                                SingleTranslationView(translation: translation, isSelected: selectedTranslation == translation)
                                    .onTapGesture {
                                        self.selectedTranslation = translation
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
//            }
                .onChange(of: selectedTranslation) { newValue in
                    if let newValue {
                        withAnimation {
                            scrollViewProxy.scrollTo(newValue.id, anchor: UnitPoint.center)
                        }
                    }
                }
        }
    }
    
}
