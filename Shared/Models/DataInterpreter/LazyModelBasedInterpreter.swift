//
//  ModelBasedInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

protocol InterpretableModel {
    init(with data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey: Any]?)
    func translationItem(at index: Int) -> TranslationItem
    static func modelSize(is64Bit: Bool) -> Int
    static func numberOfTranslationItems() -> Int
}

class LazyModelBasedInterpreter<Model: InterpretableModel>: BaseInterpreter<[Model]> {
    
    private var modelsCache: [Model?]
    private let numberOfAllTranslationItems: Int
    
    required init(_ data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey : Any]? = nil) {
        let modelSize = Model.modelSize(is64Bit: is64Bit)
        let numberOfModels = data.count / modelSize
        self.numberOfAllTranslationItems = numberOfModels * Model.numberOfTranslationItems()
        self.modelsCache = [Model?](repeating: nil, count: numberOfModels)
        super.init(data, is64Bit: is64Bit, settings: settings)
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
        if let model = modelsCache[index] {
            return model
        } else {
            let modelSize = Model.modelSize(is64Bit: self.is64Bit)
            let modelData = data.truncated(from: index * modelSize, length: modelSize)
            let model = Model(with: modelData, is64Bit: self.is64Bit, settings: self.settings)
            modelsCache[index] = model
            return model
        }
    }
}
