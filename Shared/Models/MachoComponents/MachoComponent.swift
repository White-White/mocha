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
    var componentFileOffset: Int { dataSlice.startOffset }
    var componentSize: Int { dataSlice.count }
    
    var componentTitle: String { fatalError() /* to be overriden */ }
    var componentSubTitle: String? { nil }
    
    init(_ dataSlice: DataSlice) {
        self.dataSlice = dataSlice
    }
    
    func numberOfTranslationSections() -> Int {
        fatalError()
    }
    
    func numberOfTranslationItems(at section: Int) -> Int {
        fatalError()
    }
    
    func translationItem(at indexPath: IndexPath) -> TranslationItem {
        fatalError()
    }
    
    var firstTransItem: TranslationItem? {
        return self.translationItem(at: .init(item: .zero, section: .zero))
    }
}

class MachoUnknownCodeComponent: MachoComponent {
    
    override var componentTitle: String { title }
    override var componentSubTitle: String? { subTitle }
    
    let title: String
    let subTitle: String?
    
    init(_ dataSlice: DataSlice, title: String, subTitle: String?) {
        self.title = title
        self.subTitle = subTitle
        super.init(dataSlice)
    }
    
    override func numberOfTranslationSections() -> Int {
        return 1
    }
    
    override func numberOfTranslationItems(at section: Int) -> Int {
        return 1
    }
    
    override func translationItem(at indexPath: IndexPath) -> TranslationItem {
        return TranslationItem(sourceDataRange: nil,
                               content: TranslationItemContent(description: "Code",
                                                               explanation: "This part of the macho is machine code. Hopper.app would be a better choice to parse it."))
    }
}
