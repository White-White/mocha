//
//  LCDyldInfo.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/9.
//

import Foundation

class LCDyldInfo: LoadCommand {
    
    let rebaseOffset: UInt32
    let rebaseSize: UInt32
    
    let bindOffset: UInt32
    let bindSize: UInt32
    
    let weakBindOffset: UInt32
    let weakBindSize: UInt32
    
    let lazyBindOffset: UInt32
    let lazyBindSize: UInt32
    
    let exportOffset: UInt32
    let exportSize: UInt32
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.rebaseOffset = dataShifter.shiftUInt32()
        self.rebaseSize = dataShifter.shiftUInt32()
        self.bindOffset = dataShifter.shiftUInt32()
        self.bindSize = dataShifter.shiftUInt32()
        self.weakBindOffset = dataShifter.shiftUInt32()
        self.weakBindSize = dataShifter.shiftUInt32()
        self.lazyBindOffset = dataShifter.shiftUInt32()
        self.lazyBindSize = dataShifter.shiftUInt32()
        self.exportOffset = dataShifter.shiftUInt32()
        self.exportSize = dataShifter.shiftUInt32()
        super.init(data, type: type)
    }
    
    override var commandTranslations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(description: "Rebase Info File Offset", explanation: rebaseOffset.hex, bytesCount: 4))
        translations.append(Translation(description: "Rebase Info Size", explanation: rebaseSize.hex, bytesCount: 4))
        translations.append(Translation(description: "Binding Info File Offset", explanation: bindOffset.hex, bytesCount: 4))
        translations.append(Translation(description: "Binding Info Size", explanation: bindSize.hex, bytesCount: 4))
        translations.append(Translation(description: "Weak Binding Info File Offset", explanation: weakBindOffset.hex, bytesCount: 4))
        translations.append(Translation(description: "Weak Binding Info Size", explanation: weakBindSize.hex, bytesCount: 4))
        translations.append(Translation(description: "Lazy Binding Info File Offset", explanation: lazyBindOffset.hex, bytesCount: 4))
        translations.append(Translation(description: "Lazy Binding Info Size", explanation: lazyBindSize.hex, bytesCount: 4))
        translations.append(Translation(description: "Export Info File Offset", explanation: exportOffset.hex, bytesCount: 4))
        translations.append(Translation(description: "Export Info Size", explanation: exportSize.hex, bytesCount: 4))
        return translations
    }
    
    func dyldInfoComponents(machoData: Data, machoHeader: MachoHeader) -> [MachoComponent] {
        let is64Bit = machoHeader.is64Bit
        var components: [MachoComponent] = []
        let rebaseInfoStart = Int(self.rebaseOffset)
        let rebaseInfoSize = Int(self.rebaseSize)
        if rebaseInfoStart.isNotZero && rebaseInfoSize.isNotZero {
            let rebaseInfoData = machoData.subSequence(from: rebaseInfoStart, count: rebaseInfoSize)
            let rebaseInfoComponent = OperationCodeComponent<RebaseOperationCodeMetadata>(rebaseInfoData,
                                                                                          title: "Rebase Opcode",
                                                                                          subTitle: Constants.segmentNameLINKEDIT)
            components.append(rebaseInfoComponent)
        }
        
        
        let bindInfoStart = Int(self.bindOffset)
        let bindInfoSize = Int(self.bindSize)
        if bindInfoStart.isNotZero && bindInfoSize.isNotZero {
            let bindInfoData = machoData.subSequence(from: bindInfoStart, count: bindInfoSize)
            let bindingInfoComponent = OperationCodeComponent<BindOperationCodeMetadata>(bindInfoData,
                                                                                         title: "Binding Opcode",
                                                                                         subTitle: Constants.segmentNameLINKEDIT)
            components.append(bindingInfoComponent)
        }
        
        let weakBindInfoStart = Int(self.weakBindOffset)
        let weakBindSize = Int(self.weakBindSize)
        if weakBindInfoStart.isNotZero && weakBindSize.isNotZero {
            let weakBindData = machoData.subSequence(from: weakBindInfoStart, count: weakBindSize)
            let weakBindingInfoComponent = OperationCodeComponent<BindOperationCodeMetadata>(weakBindData,
                                                                                             title: "Weak Binding Opcode",
                                                                                             subTitle: Constants.segmentNameLINKEDIT)
            components.append(weakBindingInfoComponent)
        }
        
        let lazyBindInfoStart = Int(self.lazyBindOffset)
        let lazyBindSize = Int(self.lazyBindSize)
        if lazyBindInfoStart.isNotZero && lazyBindSize.isNotZero {
            let lazyBindData = machoData.subSequence(from: lazyBindInfoStart, count: lazyBindSize)
            let lazyBindingInfoComponent = OperationCodeComponent<BindOperationCodeMetadata>(lazyBindData,
                                                                                             title: "Lazy Binding Opcode",
                                                                                             subTitle: Constants.segmentNameLINKEDIT)
            components.append(lazyBindingInfoComponent)
        }
        
        let exportInfoStart = Int(self.exportOffset)
        let exportInfoSize = Int(self.exportSize)
        if exportInfoStart.isNotZero && exportInfoSize.isNotZero {
            let exportInfoData = machoData.subSequence(from: exportInfoStart, count: exportInfoSize)
            let exportInfoComponent = ExportInfoComponent(exportInfoData,
                                                          title: "Export Info",
                                                          subTitle: Constants.segmentNameLINKEDIT, is64Bit: is64Bit)
            components.append(exportInfoComponent)
        }
        
        return components
    }
}
