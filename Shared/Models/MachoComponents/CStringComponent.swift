//
//  CStringInterpreter.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/2.
//

import Foundation

struct CStringModel {
    let startOffset: Int
    let length: Int
    let content: String?
    let demangled: String?
}

class CStringComponent: MachoComponent {
    
    private let demanglingCString: Bool
    private let virtualAddress: UInt64
    private(set) var cStrings: [CStringModel] = []
    
    init(_ data: Data, title: String, subTitle: String, virtualAddress: UInt64, demanglingCString: Bool) {
        self.demanglingCString = demanglingCString
        self.virtualAddress = virtualAddress
        super.init(data, title: title, subTitle: subTitle)
    }
    
    override func initialize() {
        var nextStringStartIndex: Int = 0
        for (currentIndex, byte) in self.data.enumerated() {
            guard byte == 0 else { continue /* skip non null */ }
            let nextStringEndIndex = currentIndex + 1
            let nextCStringDataLength = nextStringEndIndex - nextStringStartIndex
            let string = self.data.subSequence(from: nextStringStartIndex, count: nextCStringDataLength).utf8String
            let demangled = self.demanglingCString ? swift_demangle(string) : nil
            self.cStrings.append(CStringModel(startOffset: nextStringStartIndex, length: nextCStringDataLength, content: string, demangled: demangled))
            nextStringStartIndex = nextStringEndIndex
        }
    }
    
    override func createTranslations() -> [Translation] {
        return self.cStrings.map {
            Translation(description: $0.content == nil ? "Unable to decode" : "UTF8-String",
                        explanation: $0.content ?? "🙅‍♂️ Invalid UTF8 String",
                        bytesCount: $0.length,
                        extraDescription: self.demanglingCString ? "Demangled" : nil,
                        extraExplanation: $0.demangled )
        }
    }
    
}

extension CStringComponent {
    
    func findString(at offset: Int) -> String? {
        var ret: String?
        self.withInitializationDone {
            let searchedIndex = self.cStrings.binarySearch { $0.startOffset < offset }
            ret = self.cStrings[searchedIndex].startOffset == offset ? self.cStrings[searchedIndex].content : nil
        }
        return ret
    }
    
    func findString(virtualAddress: Swift.UInt64) -> String? {
        let virtualAddressBegin = self.virtualAddress
        let virtualAddressEnd = virtualAddressBegin + UInt64(self.dataSize)
        if virtualAddress < virtualAddressBegin || virtualAddress >= virtualAddressEnd { return nil }
        var finded: String?
        self.withInitializationDone {
            for cString in self.cStrings {
                if UInt64(cString.startOffset) + virtualAddressBegin == virtualAddress {
                    finded = cString.content
                    break;
                }
            }
        }
        return finded
    }
    
}
