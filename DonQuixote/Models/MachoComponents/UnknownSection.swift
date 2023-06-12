//
//  UnknownSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/8/4.
//

import Foundation

class UnknownSection: MachoBaseElement {
    
    override func loadTranslations() async {
        await self.save(translationGroup: [Translation(definition: "Unknow",
                                                              humanReadable: "Mocha doesn's know how to parse this section yet.",
                                                              translationType: .rawData(0))])
    }
    
}
