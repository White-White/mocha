//
//  MachoComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation

class MachoComponent: Equatable, TranslationDataSource {
    
    static func == (lhs: MachoComponent, rhs: MachoComponent) -> Bool {
        return lhs.machoDataSlice == rhs.machoDataSlice
    }
    
    let machoDataSlice: DataSlice
    var size: Int { machoDataSlice.count }
    var fileOffsetInMacho: Int { machoDataSlice.startIndex }
    
    var componentTitle: String { fatalError() /* to be overriden */ }
    var componentSubTitle: String? { nil }
    var componentDescription: String? { nil }
    
    init(_ machoDataSlice: DataSlice) {
        self.machoDataSlice = machoDataSlice
    }
    
    var firstTransItem: TranslationItem {
        self.translationItem(at: .zero)
    }
    
    var numberOfTranslationItems: Int {
        return 1 /* default 1 */
    }
    
    func translationItem(at index: Int) -> TranslationItem {
        fatalError()
    }
}

class MachoInterpreterBasedComponent: MachoComponent {
    
    let interpreter: Interpreter
    
    override var componentTitle: String { title }
    override var componentSubTitle: String? { subTitle }
    override var componentDescription: String? { description }
    let title: String
    let subTitle: String?
    let description: String?
    
    init(_ machoDataSlice: DataSlice,
         is64Bit: Bool,
         interpreter: Interpreter,
         title: String,
         subTitle: String? = nil,
         description: String? = nil) {
        self.interpreter = interpreter
        self.title = title
        self.subTitle = subTitle
        self.description = description
        super.init(machoDataSlice)
    }
    
    override var numberOfTranslationItems: Int {
        return interpreter.numberOfTranslationItems
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        return interpreter.translationItem(at: index)
    }
}
