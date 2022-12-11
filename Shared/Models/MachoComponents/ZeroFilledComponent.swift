//
//  ZeroFilledComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/8/4.
//

import Foundation

class ZeroFilledComponent: MachoComponent {
    
    let runtimeSize: Int
    
    init(runtimeSize: Int, title: String) {
        self.runtimeSize = runtimeSize
        super.init(Data(), /* dummy data */ title: title)
    }
    
    override func runTranslating() -> [TranslationGroup] {
        [[GeneralTranslation(definition: "Zero Filled Section",
                      humanReadable: "This section has no data in the macho file.\nIts in memory size is \(runtimeSize.hex)",
                      bytesCount: .zero,
                      translationType: .rawData)]]
    }
    
}
