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
    var translations: [GeneralTranslation] { get }
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
    
    var translations: [GeneralTranslation] {
        var translations: [GeneralTranslation] = []
        translations.append(GeneralTranslation(definition: "flags", humanReadable: self.flags.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "parent", humanReadable: self.parent.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "name", humanReadable: self.name.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "numRequirementsInSignature", humanReadable: self.numRequirementsInSignature.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "numRequirements", humanReadable: self.numRequirements.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "associatedTypeNames", humanReadable: self.associatedTypeNames.hex, bytesCount: 4, translationType: .uint32))
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
    
    var translations: [GeneralTranslation] {
        var translations: [GeneralTranslation] = []
        translations.append(GeneralTranslation(definition: "protocolDescriptor", humanReadable: self.protocolDescriptor.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "nominalTypeDescriptor", humanReadable: self.nominalTypeDescriptor.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "protocolWitnessTable", humanReadable: self.protocolWitnessTable.hex, bytesCount: 4, translationType: .uint32))
        translations.append(GeneralTranslation(definition: "conformanceFlags", humanReadable: self.conformanceFlags.hex, bytesCount: 4, translationType: .uint32))
        return translations
    }
    
    static var dataSize: Int { 16 }
    
}

struct SwiftMetadataContainer<MetaData: SwiftMetadata> {
    
    let rawOffsetValue: Int32
    let targetOffsetInMacho: Int
    let associatedMetadata: MetaData?
    
    var translations: [GeneralTranslation] {
        if let associatedMetadata = associatedMetadata {
            return associatedMetadata.translations
        } else {
            return [GeneralTranslation(definition: "FIXME: unknown", humanReadable: "UNKNOWN", bytesCount: MetaData.dataSize, translationType: .flags)]
        }
    }
}

class SwiftMetadataComponent<MetaData: SwiftMetadata>: MachoComponent {
    
    private(set) var swiftMetadataContainers: [SwiftMetadataContainer<MetaData>] = []
    
    let virtualAddress: UInt64
    
    init(_ data: Data, title: String, virtualAddress: UInt64) {
        self.virtualAddress = virtualAddress
        super.init(data, title: title, subTitle: nil)
    }
    
    override func runInitializing() {
        guard self.data.count % 4 == 0 else { fatalError() }
        let offsetInComponent = self.offsetInMacho
        let numberOfOffsets = self.data.count / 4
        self.swiftMetadataContainers = (0..<numberOfOffsets).map { index in
            let offsetOfCurrentValue = index * 4
            let offsetValue = self.data.subSequence(from: offsetOfCurrentValue, count: 4).Int32
            let targetOffsetInMacho = offsetInComponent + offsetOfCurrentValue + Int(offsetValue)
            return SwiftMetadataContainer<MetaData>(rawOffsetValue: offsetValue,
                                                    targetOffsetInMacho: targetOffsetInMacho,
                                                    associatedMetadata: self.swiftMetadata(at: targetOffsetInMacho))
        }
    }
    
    func swiftMetadata(at targetOffsetInMacho: Int) -> MetaData? {
        guard let textConstComponent = macho?.textConstComponent else { return nil }
        let componentOffsetBegin = textConstComponent.offsetInMacho
        let componentOffsetEnd = componentOffsetBegin + textConstComponent.dataSize
        guard targetOffsetInMacho > componentOffsetBegin && targetOffsetInMacho < componentOffsetEnd else { return nil }
        let data = textConstComponent.data.subSequence(from: Int(targetOffsetInMacho - componentOffsetBegin), count: MetaData.dataSize)
        let swiftMetaData = MetaData(data: data)
        return swiftMetaData
    }
    
    override func runTranslating() -> [TranslationGroup] {
        var offsetTranslations: [GeneralTranslation] = []
        for swiftMetadataContainer in swiftMetadataContainers {
            let extraDefinition: String
            if let _ = swiftMetadataContainer.associatedMetadata {
                extraDefinition = "Targeting Position in __TEXT,__const"
            } else {
                extraDefinition = "UNKNOWN position" //FIXME
            }
            offsetTranslations.append(GeneralTranslation(definition: "Offset Value",
                                            humanReadable: String(format: "%d", swiftMetadataContainer.rawOffsetValue),
                                            bytesCount: 4,
                                            translationType: .int32,
                                            extraDefinition: extraDefinition,
                                            extraHumanReadable: swiftMetadataContainer.targetOffsetInMacho.hex))
        }
        return [offsetTranslations]
    }
    
}
