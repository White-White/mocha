//
//  SwiftMetadataComponent.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/29.
//

import Foundation

protocol SwiftMetadata {
    static var dataSize: Int { get }
    init(data: Data)
    var translations: [Translation] { get }
}

struct ProtocolDescriptor: SwiftMetadata {
    
    let flags: UInt32
    let parent: Int32
    let name: Int32
    let numRequirementsInSignature: UInt32
    let numRequirements: UInt32
    let associatedTypeNames: Int32
    
    init(data: Data) {
        guard data.count == Self.dataSize else { fatalError() }
        var dataShifter = DataShifter(data)
        self.flags = dataShifter.shiftUInt32()
        self.parent = dataShifter.shiftInt32()
        self.name = dataShifter.shiftInt32()
        self.numRequirementsInSignature = dataShifter.shiftUInt32()
        self.numRequirements = dataShifter.shiftUInt32()
        self.associatedTypeNames = dataShifter.shiftInt32()
    }
    
    var translations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(definition: "flags", humanReadable: self.flags.hex, translationType: .uint32))
        translations.append(Translation(definition: "parent", humanReadable: self.parent.hex, translationType: .uint32))
        translations.append(Translation(definition: "name", humanReadable: self.name.hex, translationType: .uint32))
        translations.append(Translation(definition: "numRequirementsInSignature", humanReadable: self.numRequirementsInSignature.hex, translationType: .uint32))
        translations.append(Translation(definition: "numRequirements", humanReadable: self.numRequirements.hex, translationType: .uint32))
        translations.append(Translation(definition: "associatedTypeNames", humanReadable: self.associatedTypeNames.hex, translationType: .uint32))
        return translations
    }
    
    static var dataSize: Int { 24 }
    
}

struct ProtocolConformanceDescriptor: SwiftMetadata {
    
    let protocolDescriptor: Int32
    let nominalTypeDescriptor: Int32
    let protocolWitnessTable: Int32
    let conformanceFlags: UInt32
    
    init(data: Data) {
        guard data.count == Self.dataSize else { fatalError() }
        var dataShifter = DataShifter(data)
        self.protocolDescriptor = dataShifter.shiftInt32()
        self.nominalTypeDescriptor = dataShifter.shiftInt32()
        self.protocolWitnessTable = dataShifter.shiftInt32()
        self.conformanceFlags = dataShifter.shiftUInt32()
    }
    
    var translations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(definition: "protocolDescriptor", humanReadable: self.protocolDescriptor.hex, translationType: .uint32))
        translations.append(Translation(definition: "nominalTypeDescriptor", humanReadable: self.nominalTypeDescriptor.hex, translationType: .uint32))
        translations.append(Translation(definition: "protocolWitnessTable", humanReadable: self.protocolWitnessTable.hex, translationType: .uint32))
        translations.append(Translation(definition: "conformanceFlags", humanReadable: self.conformanceFlags.hex, translationType: .uint32))
        return translations
    }
    
    static var dataSize: Int { 16 }
    
}

struct SwiftMetadataContainer<MetaData: SwiftMetadata> {
    
    let rawOffsetValue: Int32
    let targetOffsetInMacho: Int
    let associatedMetadata: MetaData?
    
    var translations: [Translation] {
        if let associatedMetadata = associatedMetadata {
            return associatedMetadata.translations
        } else {
            return [Translation(definition: "FIXME: unknown", humanReadable: "UNKNOWN", translationType: .flags(MetaData.dataSize))]
        }
    }
}

class SwiftMetadataSection<MetaData: SwiftMetadata>: MachoBaseElement {
    
    private let swiftMetadataContainers: [SwiftMetadataContainer<MetaData>]
    
    let virtualAddress: UInt64
    
    init(_ data: Data, title: String, virtualAddress: UInt64) {
        
        self.virtualAddress = virtualAddress
        
        guard data.count % 4 == 0 else { fatalError() }
//        let offsetInComponent = self.offsetInMacho
//        let numberOfOffsets = self.data.count / 4
        self.swiftMetadataContainers = []
        
//        (0..<numberOfOffsets).map { index in
//            let offsetOfCurrentValue = index * 4
//            let offsetValue = self.data.subSequence(from: offsetOfCurrentValue, count: 4).Int32
//            let targetOffsetInMacho = offsetInComponent + offsetOfCurrentValue + Int(offsetValue)
//            return SwiftMetadataContainer<MetaData>(rawOffsetValue: offsetValue,
//                                                    targetOffsetInMacho: targetOffsetInMacho,
//                                                    associatedMetadata: self.swiftMetadata(at: targetOffsetInMacho))
//        }
        super.init(data, title: title, subTitle: nil)
    }
    
    override func loadTranslations() async {
        
    }
    
//    func swiftMetadata(at targetOffsetInMacho: Int) -> MetaData? {
//        guard let textConstComponent = macho?.textConstComponent else { return nil }
//        let componentOffsetBegin = textConstComponent.offsetInMacho
//        let componentOffsetEnd = componentOffsetBegin + textConstComponent.dataSize
//        guard targetOffsetInMacho > componentOffsetBegin && targetOffsetInMacho < componentOffsetEnd else { return nil }
//        let data = textConstComponent.data.subSequence(from: Int(targetOffsetInMacho - componentOffsetBegin), count: MetaData.dataSize)
//        let swiftMetaData = MetaData(data: data)
//        return swiftMetaData
//    }
    
//    override func runTranslating() -> [TranslationGroup] {
//        var offsetTranslations: [GeneralTranslation] = []
//        for swiftMetadataContainer in swiftMetadataContainers {
//            let extraDefinition: String
//            if let _ = swiftMetadataContainer.associatedMetadata {
//                extraDefinition = "Targeting Position in __TEXT,__const"
//            } else {
//                extraDefinition = "UNKNOWN position" //FIXME
//            }
//            offsetTranslations.append(GeneralTranslation(definition: "Offset Value",
//                                            humanReadable: String(format: "%d", swiftMetadataContainer.rawOffsetValue),
//                                            bytesCount: 4,
//                                            translationType: .int32,
//                                            extraDefinition: extraDefinition,
//                                            extraHumanReadable: swiftMetadataContainer.targetOffsetInMacho.hex))
//        }
//        return [offsetTranslations]
//    }
    
}