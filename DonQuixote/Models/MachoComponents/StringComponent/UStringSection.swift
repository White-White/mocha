//
//  UStringSection.swift
//  DonQuixote
//
//  Created by white on 2023/6/11.
//

import Foundation

class UStringSection: StringSection {
    
    init(data: Data, title: String, subTitle: String?) {
        super.init(encoding: .utf16LittleEndian, data: data, title: title, subTitle: subTitle)
    }
    
}
