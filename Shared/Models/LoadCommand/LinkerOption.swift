//
//  LinkerOption.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LCLinkerOption: LoadCommand {
    
    let numberOfOptions: Int
    let options: [String]
    override var translationDividerName: String? { "Linker Option" }
    
    override init(with loadCommandData: DataSlice, loadCommandType: LoadCommandType) {
        self.numberOfOptions = Int(loadCommandData.truncated(from: 8, length: 4).raw.UInt32)
        self.options = loadCommandData.truncated(from: 12).raw.split(separator: 0x00).map {
            if let optionString = String(data: $0, encoding: .utf8) {
                return optionString
            } else {
                return Log.warning("Unexpected, found unknown linker option. Breakpoint to debug")
            }
        }
        super.init(with: loadCommandData, loadCommandType: loadCommandType)
    }
    
    override func translationSection(at index: Int) -> TransSection {
        let section = super.translationSection(at: index)
        section.translateNextDoubleWord { Readable(description: "Number of options", explanation: "\(self.numberOfOptions)") }
        section.translateNext(self.machoDataSlice.count - 12) { Readable(description: "Content", explanation: "\(self.options.joined(separator: " "))") }
        return section
    }
}
