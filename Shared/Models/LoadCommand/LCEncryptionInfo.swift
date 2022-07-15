//
//  EncryptionInfo.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

//struct encryption_info_command_64 {
//   uint32_t    cmd;        /* LC_ENCRYPTION_INFO_64 */
//   uint32_t    cmdsize;    /* sizeof(struct encryption_info_command_64) */
//   uint32_t    cryptoff;    /* file offset of encrypted range */
//   uint32_t    cryptsize;    /* file size of encrypted range */
//   uint32_t    cryptid;    /* which enryption system,
//                   0 means not-encrypted yet */
//   uint32_t    pad;        /* padding to make this struct's size a multiple
//                   of 8 bytes */
//};

class LCEncryptionInfo: LoadCommand {
    
    let cryptoOffset: UInt32
    let cryptoSize: UInt32
    let cryptoID: UInt32
    let pad: UInt32?
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.cryptoOffset = dataShifter.shiftUInt32()
        self.cryptoSize = dataShifter.shiftUInt32()
        self.cryptoID = dataShifter.shiftUInt32()
        self.pad = (type == .encryptionInfo64 ? dataShifter.shiftUInt32() : nil)
        super.init(data, type: type)
    }
    
    override var commandTranslations: [Translation] {
        var translations: [Translation] = []
        translations.append(Translation(description: "Crypto File Offset", explanation: self.cryptoOffset.hex, bytesCount: 4))
        translations.append(Translation(description: "Crypto File Size", explanation: self.cryptoSize.hex, bytesCount: 4))
        translations.append(Translation(description: "Crypto ID", explanation: "\(self.cryptoID)", bytesCount: 4))
        if let pad = self.pad { translations.append(Translation(description: "Crypto Pad", explanation: "\(pad)", bytesCount: 4)) }
        return translations
    }
    
}
