//
//  ModelBasedLazyComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

protocol InterpretableModel {
    init(with data: Data, is64Bit: Bool, macho: Macho)
    func translationItem(at index: Int) -> TranslationItem
    static func modelSize(is64Bit: Bool) -> Int
    static func numberOfTranslationItems() -> Int
}

class ModelBasedLazyComponent<Model: InterpretableModel>: MachoLazyComponent<[Model]> {
    
    override var shouldPreload: Bool { true }
    
    override func generatePayload() -> [Model] {
        let modelSize = Model.modelSize(is64Bit: is64Bit)
        let numberOfModels = data.count / modelSize
        var models: [Model] = []
        for index in 0..<numberOfModels {
            let modelSize = Model.modelSize(is64Bit: self.is64Bit)
            let modelData = data.subSequence(from: index * modelSize, count: modelSize)
            let model = Model(with: modelData, is64Bit: self.is64Bit, macho: macho)
            models.append(model)
        }
        return models
    }
    
    override func numberOfTranslationSections() -> Int {
        return self.payload.count
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return Model.numberOfTranslationItems()
    }

    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        return self.payload[indexPath.section].translationItem(at: indexPath.item)
    }
}
