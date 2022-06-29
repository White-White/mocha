//
//  MachoZeroFilledComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/28.
//

import Foundation

class MachoZeroFilledComponent: MachoComponent {
    
    override var componentTitle: String { title }
    override var componentSubTitle: String? { subTitle }
    
    let title: String
    let subTitle: String?
    let runtimeSize: Int
    
    init(runtimeSize: Int, title: String, subTitle: String? = nil) {
        self.runtimeSize = runtimeSize
        self.title = title
        self.subTitle = subTitle
        super.init(DataSlice(Data([0xcf, 0xfa, 0xed, 0xfe])) /* dummy data */ )
    }
    
    override func numberOfTranslationSections() -> Int {
        return 1
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        return TranslationItem(sourceDataRange: nil, content: TranslationItemContent(description: "Zero Filled Section",
                                                                                     explanation: "This section has no data in the macho file.\nIts in memory size is \(runtimeSize.hex)",
                                                                                     explanationStyle: ExplanationStyle.extraDetail))
    }
    
    override var firstTransItem: TranslationItem? {
        return nil
    }
}
