//
//  StringSection.swift
//  DonQuixote
//
//  Created by white on 2023/6/11.
//

import Foundation

class StringSection: MachoBaseElement {
    
    let encoding: String.Encoding
    let stringContainer: StringContainer
    
    init(encoding: String.Encoding, data: Data, title: String, subTitle: String?) {
        self.encoding = encoding
        self.stringContainer = StringContainer(data: data, encoding: encoding, shouldDemangle: false) // TODO: should disable mangling?
        super.init(data, title: title, subTitle: subTitle)
    }
    
    override func loadTranslations() async {
        for rawString in await self.stringContainer.rawStrings {
            let stringContent = await self.stringContainer.stringContent(for: rawString)
            let translation = GeneralTranslation(definition: nil,
                                                 humanReadable: stringContent.content ?? "Invalid \(self.encoding) string. Debug me",
                                                 bytesCount: stringContent.byteCount,
                                                 translationType: .utf8String,
                                                 extraDefinition: stringContent.demangled != nil ? "Demangled" : nil,
                                                 extraHumanReadable: stringContent.demangled)
            await self.save(translationGroup: [translation])
        }
    }
    
    func findString(atDataOffset offset: Int) async -> String? {
        if let stringContent = await self.stringContainer.stringContent(withOffset: offset) {
            return stringContent.content ?? "Finded. But fail to decode. Debug me."
        }
        return nil
    }
    
}
