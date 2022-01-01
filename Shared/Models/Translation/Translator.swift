//
//  CStringTranslator.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/30.
//

import Foundation

protocol Translator {
    init(_ data: SmartData, is64Bit: Bool)
    var numberOfTransSections: Int { get }
    func transSection(at index: Int) -> TransSection
    func preload()
}

class AnonymousTranslator: Translator {
    
    private let data: SmartData
    var description: String { "Anonymous" }
    var explanation: String { "Dont know how to translate this binary." }
    
    required init(_ data: SmartData, is64Bit: Bool) {
        self.data = data
    }
    
    var numberOfTransSections: Int {
        return 1
    }
    
    func transSection(at index: Int) -> TransSection {
        let section = TransSection(baseIndex: data.startOffsetInMacho, title: nil)
        section.addTranslation(forRange: nil) { Readable(description: self.description, explanation: self.explanation) }
        return section
    }
    
    func preload() { }
}

class ModelTranslator<Model: TranslatableModel>: Translator {
    
    private let data: SmartData
    private let is64Bit: Bool
    private let asyncLoader = AsyncLoader<[Model]>()
    
    required init(_ data: SmartData, is64Bit: Bool) {
        self.data = data
        self.is64Bit = is64Bit
    }
    
    var numberOfTransSections: Int {
        return asyncLoader.assertLoaded.count
    }
    
    func transSection(at index: Int) -> TransSection {
        return asyncLoader.assertLoaded[index].makeTransSection()
    }
    
    func preload() {
        asyncLoader.load {
            let modelSize = Model.modelSize(is64Bit: self.is64Bit)
            let numberOfModels = self.data.count / modelSize
            var models: [Model] = []
            for index in 0..<numberOfModels {
                let data = self.data.truncated(from: index * modelSize, length: modelSize)
                models.append(Model(with: data, is64Bit: self.is64Bit))
            }
            return models
        }
    }
}

class CStringTranslator: Translator {
    
    private let cStringData: SmartData
    private let asyncLoader: AsyncLoader = AsyncLoader<[TransSection]>()
    
    required init(_ data: SmartData, is64Bit: Bool) {
        self.cStringData = data
    }
    
    var numberOfTransSections: Int {
        return asyncLoader.assertLoaded.count
    }
    
    func transSection(at index: Int) -> TransSection {
        return asyncLoader.assertLoaded[index]
    }
 
    func preload() {
        asyncLoader.load {
            let cStringDataBaseOffset = self.cStringData.startOffsetInMacho
            let rawData = self.cStringData.raw
            
            var transSection: [TransSection] = []
            var indexOfLastNull: Int? // index of last null char ( "\0" )
            
            for (indexOfCurNull, byte) in rawData.enumerated() {
                
                guard byte == 0 else { continue } // find null characters

                let lastIndex = indexOfLastNull ?? -1
                if indexOfCurNull - lastIndex == 1 {
                    indexOfLastNull = indexOfCurNull // skip continuous \0
                    continue
                }
                
                let nextCStringStartIndex = lastIndex + 1 // lastIdnex points to last null, ignore
                let nextCStringDataLength = indexOfCurNull - nextCStringStartIndex
                let nextCStringRawData = rawData.select(from: nextCStringStartIndex, length: nextCStringDataLength)
                
                let section = TransSection(baseIndex: cStringDataBaseOffset + nextCStringStartIndex)
                if let string = String(data: nextCStringRawData, encoding: .utf8) {
                    section.translateNext(nextCStringDataLength) {
                        Readable(description: "UTF8 encoded string", explanation: string.replacingOccurrences(of: "\n", with: "\\n"))
                    }
                } else {
                    section.translateNext(nextCStringDataLength) {
                        Readable(description: "Invalid utf8 encoded", explanation: "🙅‍♂️ Invalid utf8 string")
                    }
                }
                transSection.append(section)
                indexOfLastNull = indexOfCurNull
            }
            
            return transSection
        }
    }
}
