//
//  Error.swift
//  DonQuixote
//
//  Created by white on 2023/6/12.
//

import Foundation

enum DonError: Error {
    case invalidFileURL
    case invalidIPABundle
    case invalidIPAPlist
    case unknownApplePlatform
}
