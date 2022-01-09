//
//  LCDyldInfo.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/9.
//

import Foundation

class LCDyldInfo: LoadCommand {
    
    let rebaseOffset: UInt32
    let rebaseSize: UInt32
    
    let bindOffset: UInt32
    let bindSize: UInt32
    
    let weakBindOffset: UInt32
    let weakBindSize: UInt32
    
    let lazyBindOffset: UInt32
    let lazyBindSize: UInt32
    
    let exportOffset: UInt32
    let exportSize: UInt32
    
    required init(with type: LoadCommandType, data: DataSlice, itemsContainer: TranslationItemContainer? = nil) {
        let itemsContainer = TranslationItemContainer(machoDataSlice: data, sectionTitle: nil).skip(.quadWords)
        
        self.rebaseOffset =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Rebase Info File Offset", explanation: value.hex) })
        
        self.rebaseSize =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Rebase Info Size", explanation: "\(value)") })
        
        self.bindOffset =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Binding Info File Offset", explanation: value.hex) })
        
        self.bindSize =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Binding Info Size", explanation: "\(value)") })
        
        self.weakBindOffset =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Weak Binding Info File Offset", explanation: value.hex) })
        
        self.weakBindSize =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Weak Binding Info Size", explanation: "\(value)") })
        
        self.lazyBindOffset =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Lazy Binding Info File Offset", explanation: value.hex) })
        
        self.lazyBindSize =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Lazy Binding Info Size", explanation: "\(value)") })
        
        self.exportOffset =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Export Info File Offset", explanation: value.hex) })
        
        self.exportSize =
        itemsContainer.translate(next: .doubleWords,
                                 dataInterpreter: DataInterpreterPreset.UInt32,
                                 itemContentGenerator: { value in TranslationItemContent(description: "Export Info Size", explanation: "\(value)") })
        
        super.init(with: type, data: data, itemsContainer: itemsContainer)
    }
}
