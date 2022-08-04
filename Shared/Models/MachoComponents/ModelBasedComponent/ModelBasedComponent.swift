//
//  ModelBasedComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/11.
//

import Foundation

protocol InterpretableModel {
    init(with data: Data, is64Bit: Bool, macho: Macho)
    var translations: [Translation] { get }
    static var modelSizeFor64Bit: Int { get }
    static var modelSizeFor32Bit: Int { get }
}

class ModelBasedComponent<Model: InterpretableModel>: ModeledTranslationComponent {
    
    private(set) var models: [Model] = []
    let modelSize: Int
    let is64Bit: Bool
    
    init(_ data: Data, title: String, is64Bit: Bool) {
        self.is64Bit = is64Bit
        self.modelSize = is64Bit ? Model.modelSizeFor64Bit : Model.modelSizeFor32Bit
        super.init(data, title: title)
    }
    
    override func asyncInitialize() {
        var dataShifter = DataShifter(self.data)
        while dataShifter.shiftable {
            let modelData = dataShifter.shift(.rawNumber(self.modelSize))
            self.models.append(Model(with: modelData, is64Bit: self.is64Bit, macho: self.macho!))
        }
    }
    
    override func createTranslationSections() -> [TranslationSection] {
        var translationSections: [TranslationSection] = []
        let maxIndex = self.models.count - 1
        for (index, model) in self.models.enumerated() {
            translationSections.append(TranslationSection(translations: model.translations))
            self.initProgress.updateTranslationInitializeProgress(Float(index) / Float(maxIndex))
        }
        self.initProgress.updateTranslationInitializeProgress(1)
        return translationSections
    }
    
}


