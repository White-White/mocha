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
    
    let data: Data
    var fileOffset: Int { data.startIndex }
    var dataSize: Int { data.count }
    
    var componentTitle: String { fatalError() /* to be overriden */ }
    var componentSubTitle: String? { nil }
    
    init(_ data: Data) {
        self.data = data
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

}

class MachoUnknownCodeComponent: MachoComponent {
    
    override var componentTitle: String { title }
    override var componentSubTitle: String? { subTitle }
    
    let title: String
    let subTitle: String?
    
    init(_ data: Data, title: String, subTitle: String?) {
        self.title = title
        self.subTitle = subTitle
        super.init(data)
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
