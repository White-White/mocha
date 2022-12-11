//
//  RelocationTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/13.
//

import Foundation

struct RelocationInfo {
    let numberOfEntries: Int
    let sectionName: String
}

class RelocationTable: MachoComponent {
    
    var relocationEntries: [RelocationEntry] = []
    let relocationInfos: [RelocationInfo]
    
    init(data: Data, relocationInfos: [RelocationInfo]) {
        self.relocationInfos = relocationInfos
        super.init(data, title: "Relocation Table")
    }
    
    override func runInitializing() {
        var dataShifter = DataShifter(self.data)
        self.relocationInfos.forEach { info in
            for _ in 0..<info.numberOfEntries {
                let entryData = dataShifter.shift(.rawNumber(RelocationEntry.entrySize))
                self.relocationEntries.append(RelocationEntry(with: entryData, sectionName: info.sectionName))
            }
        }
    }
    
    override func runTranslating() -> [TranslationGroup] {
        self.relocationEntries.map { $0.translations }
    }
    
}
