//
//  ModelBasedInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

protocol InterpretableModel {
    init(with data: DataSlice, is64Bit: Bool, settings: [InterpreterSettingsKey: Any]?)
    func makeTransSection() -> TransSection
    static func modelSize(is64Bit: Bool) -> Int
}

class ModelBasedInterpreter<Model: InterpretableModel>: BaseInterpreter<[Model]> {
    override func generatePayload() -> [Model] {
        let modelSize = Model.modelSize(is64Bit: self.is64Bit)
        let numberOfModels = self.data.count / modelSize
        var models: [Model] = []
        for index in 0..<numberOfModels {
            let data = self.data.truncated(from: index * modelSize, length: modelSize)
            models.append(Model(with: data, is64Bit: self.is64Bit, settings: self.settings))
        }
        return models
    }
    
    override func numberOfTransSections() -> Int {
        return self.payload.count
    }
    
    override func transSection(at index: Int) -> TransSection {
        return self.payload[index].makeTransSection()
    }
}
