//
//  UnknownComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/8/4.
//

import Foundation

class UnknownComponent: MachoComponentWithTranslations {
    
    override func createTranslations() -> [Translation] {
        return [Translation(definition: "Unknow",
                            humanReadable: "Mocha doesn's know how to parse this section yet.",
                            bytesCount: .zero,
                            translationType: .rawData)]
    }
    
}
