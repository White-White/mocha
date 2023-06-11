//
//  MachoBaseElement.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation
import SwiftUI

typealias TranslationGroup = [BaseTranslation]

actor TranslationsContainer: ObservableObject {
    
    @MainActor @Published var translationGroups: [TranslationGroup] = []
    
    func save(translationGroup: TranslationGroup) {
        Task { @MainActor in
            self.translationGroups.append(translationGroup)
        }
    }
    
}

class MachoBaseElement: @unchecked Sendable, Equatable, Identifiable {
    
    static func == (lhs: MachoBaseElement, rhs: MachoBaseElement) -> Bool {
        return lhs === rhs
    }
    
    let title: String
    let subTitle: String?
    let data: Data
    var dataSize: Int { data.count }
    var offsetInMacho: Int { data.startIndex }
    let translationContainer = TranslationsContainer()
    
    let initProgress = InitProgress()
    
    init(_ data: Data, title: String, subTitle: String?) {
        self.data = data
        self.title = title
        self.subTitle = subTitle
        self.asyncLoadTranslations()
    }
    
    func loadTranslations() async {
        fatalError()
    }
    
    final func save(translationGroup: TranslationGroup) async {
        await self.translationContainer.save(translationGroup: translationGroup)
    }
    
    private func asyncLoadTranslations() {
        Task {
            await self.loadTranslations()
        }
    }
    
    var dataRangeInMacho: Range<UInt64> { UInt64(self.offsetInMacho)..<UInt64(self.offsetInMacho + self.dataSize) }

}
