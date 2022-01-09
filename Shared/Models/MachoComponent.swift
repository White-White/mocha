//
//  MachoComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation

class MachoComponent: Equatable {
    
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
    
    func numberOfTranslationSections() -> Int {
        return 1 /* default 1 */
    }
    
    func translationItems(at section: Int) -> [TranslationItem] {
        fatalError()
    }
    
    func sectionTile(of section: Int) -> String? {
        return nil
    }
    
    var firstTransItem: TranslationItem? {
        self.translationItems(at: .zero).first
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
         interpreterType: Interpreter.Type,
         title: String,
         interpreterSettings: [InterpreterSettingsKey: Any]? = nil,
         subTitle: String? = nil,
         description: String? = nil) {
        self.interpreter = interpreterType.init(machoDataSlice, is64Bit: is64Bit, settings: interpreterSettings)
        self.title = title
        self.subTitle = subTitle
        self.description = description
        super.init(machoDataSlice)
    }
    
    override func numberOfTranslationSections() -> Int {
        return interpreter.numberOfTranslationSections()
    }
    
    override func translationItems(at section: Int) -> [TranslationItem] {
        return interpreter.translationItems(at: section)
    }
    
    override func sectionTile(of section: Int) -> String? {
        return interpreter.sectionTitle(of: section)
    }
}
