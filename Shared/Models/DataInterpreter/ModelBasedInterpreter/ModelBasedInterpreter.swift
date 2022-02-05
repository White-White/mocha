//
//  ModelBasedInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

protocol InterpretableModel {
    init(with data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource)
    func translationItem(at index: Int) -> TranslationItem
    static func modelSize(is64Bit: Bool) -> Int
    static func numberOfTranslationItems() -> Int
}

class ModelBasedInterpreter<Model: InterpretableModel>: BaseInterpreter<[Model]> {
    
    override var shouldPreload: Bool { true }
    
    override func generatePayload() -> [Model] {
        let modelSize = Model.modelSize(is64Bit: is64Bit)
        let numberOfModels = data.count / modelSize
        var models: [Model] = []
        for index in 0..<numberOfModels {
            let modelSize = Model.modelSize(is64Bit: self.is64Bit)
            let modelData = data.truncated(from: index * modelSize, length: modelSize)
            let model = Model(with: modelData, is64Bit: self.is64Bit, machoSearchSource: self.machoSearchSource)
            models.append(model)
        }
        return models
    }

    override var numberOfTranslationItems: Int {
        return self.payload.count * Model.numberOfTranslationItems()
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let numberOfTransItemsPerModel = Model.numberOfTranslationItems()
        let modelIndex = index / numberOfTransItemsPerModel
        let modelItemOffset = index % numberOfTransItemsPerModel
        return self.payload[modelIndex].translationItem(at: modelItemOffset)
    }
}

class LazyModelBasedInterpreter<Model: InterpretableModel>: BaseInterpreter<[Model]> {
    
    private let numberOfAllTranslationItems: Int
    
    override var payload: [Model] { fatalError() }
    
    override init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource) {
        let modelSize = Model.modelSize(is64Bit: is64Bit)
        let numberOfModels = data.count / modelSize
        self.numberOfAllTranslationItems = numberOfModels * Model.numberOfTranslationItems()
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }

    override var numberOfTranslationItems: Int {
        return self.numberOfAllTranslationItems
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let numberOfTransItemsPerModel = Model.numberOfTranslationItems()
        let modelIndex = index / numberOfTransItemsPerModel
        let modelItemOffset = index % numberOfTransItemsPerModel
        return self.model(at: modelIndex).translationItem(at: modelItemOffset)
    }
    
    private func model(at index: Int) -> Model {
        let modelSize = Model.modelSize(is64Bit: self.is64Bit)
        let modelData = data.truncated(from: index * modelSize, length: modelSize)
        let model = Model(with: modelData, is64Bit: self.is64Bit, machoSearchSource: machoSearchSource)
        return model
    }
}

extension ModelBasedInterpreter where Model == SymbolTableEntry {
    
    func searchSymbol(by virtualAddress: Swift.UInt64) -> SymbolTableEntry? {
        for symbolEntry in self.payload {
            if symbolEntry.nValue == virtualAddress {
                return symbolEntry
            }
        }
        return nil
    }
    
    func searchSymbol(withIndex index: Int) -> SymbolTableEntry? {
        guard index < self.payload.count else { return nil }
        return self.payload[index]
    }
}
