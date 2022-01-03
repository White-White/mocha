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
    
    var primaryName: String { fatalError() /* to be overriden */ }
    var secondaryName: String? { nil }
    
    init(_ machoDataSlice: DataSlice) {
        self.machoDataSlice = machoDataSlice
    }
    
    var numberOfTranslationSections: Int {
        return 1 /* default 1 */
    }
    
    func translationSection(at index: Int) -> TransSection {
        fatalError() /* to be overriden */
    }
}

class MachoInterpreterBasedComponent: MachoComponent {
    
    let interpreter: Interpreter
    
    override var primaryName: String { primaryNameInside }
    override var secondaryName: String? { secondaryNameInside }
    let primaryNameInside: String
    let secondaryNameInside: String?
    
    init(_ machoDataSlice: DataSlice, is64Bit: Bool, interpreterType: Interpreter.Type, primaryName: String, secondaryName: String? = nil) {
        self.interpreter = interpreterType.init(machoDataSlice, is64Bit: is64Bit)
        self.primaryNameInside = primaryName
        self.secondaryNameInside = secondaryName
        super.init(machoDataSlice)
    }
    
    override var numberOfTranslationSections: Int {
        return interpreter.numberOfTransSections()
    }
    
    override func translationSection(at index: Int) -> TransSection {
        return interpreter.transSection(at: index)
    }
}
