//
//  LCUUID.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCUUID: LoadCommand {
    
    let uuid: UUID
    
    required init(with type: LoadCommandType, data: Data, translationStore: TranslationStore? = nil) {
        let translationStore = TranslationStore(data: data).skip(.quadWords)
        self.uuid = translationStore.translate(next: .rawNumber(16),
                                             dataInterpreter: { uuidData in LCUUID.uuid(from: [UInt8](uuidData)) },
                                             itemContentGenerator: { uuid in TranslationItemContent(description: "UUID", explanation: uuid.uuidString) })
        super.init(with: type, data: data, translationStore: translationStore)
    }
    
    static func uuid(from uuidData: [UInt8]) -> UUID {
        return UUID(uuid: (uuidData[0], uuidData[1], uuidData[2], uuidData[3], uuidData[4], uuidData[5], uuidData[6], uuidData[7],
                           uuidData[8], uuidData[9], uuidData[10], uuidData[11], uuidData[12], uuidData[13], uuidData[14], uuidData[15]))
    }
}
