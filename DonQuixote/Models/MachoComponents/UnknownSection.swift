//
//  UnknownSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/8/4.
//

import Foundation

class UnknownSection: MachoBaseElement {
    
    override func loadTranslations() async {
        await self.save(translationGroup: [GeneralTranslation(definition: "Unknow",
                                                              humanReadable: "Mocha doesn's know how to parse this section yet.",
                                                              bytesCount: .zero,
                                                              translationType: .rawData)])
    }
    
}
