//
//  MachoComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation

class MachoComponent: Equatable {
    
    static func == (lhs: MachoComponent, rhs: MachoComponent) -> Bool {
        return lhs.dataSlice == rhs.dataSlice
    }
    
    let dataSlice: DataSlice
    var componentFileOffset: Int { dataSlice.startOffset }
    var componentSize: Int { dataSlice.count }
    
    var componentTitle: String { fatalError() /* to be overriden */ }
    var componentSubTitle: String? { nil }
    var componentDescription: String? { nil }
    
    init(_ dataSlice: DataSlice) {
        self.dataSlice = dataSlice
    }
    
    func numberOfTranslationSections() -> Int {
        return 1
    }
    
    func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    func translationItem(at indexPath: IndexPath) -> TranslationItem {
        fatalError()
    }
    
    var firstTransItem: TranslationItem {
        return self.translationItem(at: .init(item: .zero, section: .zero))
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
    
    override func numberOfTranslationSections() -> Int {
        return interpreter.numberOfTranslationSections()
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return interpreter.numberOfTranslationItems(at: section)
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        return interpreter.translationItem(at: indexPath)
    }
}
