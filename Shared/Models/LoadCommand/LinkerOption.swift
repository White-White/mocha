//
//  LinkerOption.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

class LinkerOption: LoadCommand {
    
    let numberOfOptions: Int
    let options: [String]
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        self.numberOfOptions = itemsContainer.translate(next: .doubleWords,
                                                        dataInterpreter: { Int($0.UInt32) },
                                                        itemContentGenerator: { number in TranslationItemContent(description: "Number of options", explanation: "\(number)") })
        
        self.options = itemsContainer.translate(next: .rawNumber(data.count - 12),
                                                dataInterpreter: { LinkerOption.options(from: $0) },
                                                itemContentGenerator: { options in TranslationItemContent(description: "Options(s)", explanation: options.joined(separator: " ")) })
        
        super.init(with: type, data: data, itemsContainer: itemsContainer)
    }
    
    static func options(from data: Data) -> [String] {
        return data.split(separator: 0x00).map {
            if let optionString = String(data: $0, encoding: .utf8) {
                return optionString
            } else {
                return Log.warning("Unexpected, found unknown linker option. Breakpoint to debug")
            }
        }
    }
}
