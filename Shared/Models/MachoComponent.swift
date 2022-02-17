//
//  MachoComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/3.
//

import Foundation

class MachoComponent: Equatable, Identifiable {
    
    static func == (lhs: MachoComponent, rhs: MachoComponent) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    let dataSlice: DataSlice
    let hexDigits: Int
    var componentFileOffset: Int { dataSlice.startOffset }
    var componentSize: Int { dataSlice.count }
    
    var componentTitle: String { fatalError() /* to be overriden */ }
    var componentSubTitle: String? { nil }
    var componentRange: String { String(format: "Range: 0x%0\(hexDigits)X - 0x%0\(hexDigits)X", componentFileOffset, componentFileOffset + componentSize) }
    
    init(_ dataSlice: DataSlice) {
        self.dataSlice = dataSlice
        var machoDataSize = dataSlice.count
        var digitCount = 0
        while machoDataSize != 0 { digitCount += 1; machoDataSize /= 16 }
        self.hexDigits = digitCount
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
    
    var firstTransItem: TranslationItem? {
        return self.translationItem(at: .init(item: .zero, section: .zero))
    }
}

class MachoZeroFilledComponent: MachoComponent {
    
    override var componentTitle: String { title }
    override var componentSubTitle: String? { subTitle }
    override var componentRange: String { "Range: N/A" }
    
    let title: String
    let subTitle: String?
    let runtimeSize: Int
    
    init(runtimeSize: Int, title: String, subTitle: String? = nil) {
        self.runtimeSize = runtimeSize
        self.title = title
        self.subTitle = subTitle
        super.init(DataSlice(Data([0xcf, 0xfa, 0xed, 0xfe])) /* dummy data */ )
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        return TranslationItem(sourceDataRange: nil, content: TranslationItemContent(description: "Zero Filled Section",
                                                                                     explanation: "This section has no data in the macho file.\nIts in memory size is \(runtimeSize.hex)",
                                                                                     explanationStyle: ExplanationStyle.extraDetail))
    }
    
    override var firstTransItem: TranslationItem? {
        return nil
    }
}

class MachoInterpreterBasedComponent: MachoComponent {
    
    let interpreter: Interpreter
    
    override var componentTitle: String { title }
    override var componentSubTitle: String? { subTitle }
    
    let title: String
    let subTitle: String?
    
    init(_ machoDataSlice: DataSlice,
         is64Bit: Bool,
         interpreter: Interpreter,
         title: String,
         subTitle: String? = nil) {
        self.interpreter = interpreter
        self.title = title
        self.subTitle = subTitle
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
    
    override var firstTransItem: TranslationItem? {
        return interpreter.defaultSelectedTranslationItem()
    }
}
