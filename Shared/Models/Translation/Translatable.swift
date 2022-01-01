//
//  Translatable.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

protocol TranslatableModel {
    init(with data: SmartData, is64Bit: Bool)
    func makeTransSection() -> TransSection
    static func modelName() -> String?
    static func modelSize(is64Bit: Bool) -> Int
}
