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
    
    private(set) var cStrings: [CStringModel] = []
    private(set) var cStringOffsetIndexMap: [Int:Int] = [:]
    
    override func initialize() {
        var currentIndex: Int = 0
        while currentIndex < self.data.count {
            var byte = self.data[self.data.startIndex + currentIndex];
            if byte == 0 {
                let continuousSpaceStartIndex = currentIndex; currentIndex += 1
                var more = true
                while (currentIndex < self.data.count && more) {
                    byte = self.data[self.data.startIndex + currentIndex]
                    if byte != 0 { more = false; break }
                    currentIndex += 1
                }
                let nextStringEndIndex = currentIndex
                let nextCStringDataLength = nextStringEndIndex - continuousSpaceStartIndex
                self.cStrings.append(CStringModel(startOffset: continuousSpaceStartIndex, length: nextCStringDataLength, content: "", demangled: nil))
            } else {
                let validStringStartIndex = currentIndex
                while (byte != 0 && currentIndex < self.data.count) {
                    byte = self.data[self.data.startIndex + currentIndex]
                    currentIndex += 1
                }
                let nextStringEndIndex = currentIndex
                let nextCStringDataLength = nextStringEndIndex - validStringStartIndex
                let string = self.data.subSequence(from: validStringStartIndex, count: nextCStringDataLength).utf8String
                let demangled: String? = nil // swift_demangle(string) TODO: should disable mangling?
                self.cStrings.append(CStringModel(startOffset: validStringStartIndex, length: nextCStringDataLength, content: string, demangled: demangled))
            }
        }
        for (index, cString) in self.cStrings.enumerated() {
            cStringOffsetIndexMap[cString.startOffset] = index
        }
    }
    
    override func createTranslations() -> [Translation] {
        return self.cStrings.map {
            Translation(definition: $0.content == nil ? "Unable to decode" : "UTF8-String",
                        humanReadable: $0.content ?? "🙅‍♂️ Invalid UTF8 String",
                        bytesCount: $0.length, translationType: .utf8String,
                        extraDefinition: $0.demangled != nil ? "Demangled" : nil,
                        extraHumanReadable: $0.demangled )
        }
    }
    
    func findString(atDataOffset offset: Int) -> String? {
        var finded: String?
        self.withInitializationDone {
            if let index = self.cStringOffsetIndexMap[offset] {
                finded = self.cStrings[index].content
            }
        }
        return finded
    }
    
}

class CStringSectionComponent: CStringComponent {
    
    private let baseVirtualAddress: UInt64
    
    init(_ data: Data, title: String, virtualAddress: UInt64) {
        self.baseVirtualAddress = virtualAddress
        super.init(data, title: title)
    }
    
    func findString(virtualAddress: Swift.UInt64) -> String? {
        let virtualAddressBegin = self.baseVirtualAddress
        let virtualAddressEnd = virtualAddressBegin + UInt64(self.dataSize)
        if virtualAddress < virtualAddressBegin || virtualAddress >= virtualAddressEnd { return nil }
        let dataOffset = Int(virtualAddress - self.baseVirtualAddress)
        return self.findString(atDataOffset: dataOffset)
    }
    
}



