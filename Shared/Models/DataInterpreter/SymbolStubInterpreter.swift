//
//  SymbolStubInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/2.
//

import Foundation

struct SymbolStub {
    let startOffset: Int
    let size: Int
}

class SymbolStubInterpreter: BaseInterpreter<[SymbolStub]> {
    
    let stubSize: Int
    override var shouldPreload: Bool { true }
    
    init(_ data: DataSlice, is64Bit: Bool, machoSearchSource: MachoSearchSource, stubSize: Int) {
        guard data.count % stubSize == 0 else { fatalError() }
        self.stubSize = stubSize
        super.init(data, is64Bit: is64Bit, machoSearchSource: machoSearchSource)
    }
    
    override func generatePayload() -> [SymbolStub] {
        var stubs: [SymbolStub] = []
        for index in 0..<data.count/stubSize {
            stubs.append(SymbolStub(startOffset: index * stubSize, size: stubSize))
        }
        return stubs
    }
    
    override var numberOfTranslationItems: Int {
        return payload.count
    }
    
    override func translationItem(at index: Int) -> TranslationItem {
        let stub = payload[index]
        let stubRawData = data.truncated(from: stub.startOffset, length: stub.size)
        return TranslationItem(sourceDataRange: data.absoluteRange(stub.startOffset, stub.size),
                               content: TranslationItemContent(description: "Stub", explanation: "Stub"))
    }
    
}
