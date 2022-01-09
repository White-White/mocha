//
//  ModelBasedInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

protocol InterpretableModel {
    init(with data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey: Any]?)
    func translationItems() -> [TranslationItem]
    static func modelSize(is64Bit: Bool) -> Int
}

class LazyModelBasedInterpreter<Model: InterpretableModel>: BaseInterpreter<[Model]> {
    
    private var modelsCache: [Model?]
    
    required init(_ data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey : Any]? = nil) {
        let modelSize = Model.modelSize(is64Bit: is64Bit)
        let numberOfModels = data.count / modelSize
        self.modelsCache = [Model?](repeating: nil, count: numberOfModels)
        super.init(data, is64Bit: is64Bit, settings: settings)
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.modelsCache.count
    }

    override func translationItems(at section: Int) -> [TranslationItem] {
        return self.model(at: section).translationItems()
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
