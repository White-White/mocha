//
//  Error.swift
//  DonQuixote
//
//  Created by white on 2023/6/12.
//

import Foundation

enum DonError: Error {
    
    case invalidFileLocation
    
    case invalidIPABundle
    case invalidIPAPlist
    case unknownApplePlatform
    case unknownFile
    
    case failToCreateFileHandle
    case failToReadFileHandle
    
    case failToReadInputStream
    
    case invalidFatBinary
}
