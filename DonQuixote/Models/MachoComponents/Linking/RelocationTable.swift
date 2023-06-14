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

class RelocationTable: MachoBaseElement {
    
    var relocationEntries: [RelocationEntry] = []
    let relocationInfos: [RelocationInfo]
    
    init(data: Data, relocationInfos: [RelocationInfo]) {
        self.relocationInfos = relocationInfos
        super.init(data, title: "Relocation Table", subTitle: nil)
    }
    
    override func loadTranslations() async {
        var dataShifter = DataShifter(self.data)
        for relocationInfo in relocationInfos {
            for _ in 0..<relocationInfo.numberOfEntries {
                let entryData = dataShifter.shift(.rawNumber(RelocationEntry.entrySize))
                let entry = RelocationEntry(with: entryData, sectionName: relocationInfo.sectionName)
                await self.save(translations: entry.translations)
            }
        }
    }
    
}
