//
//  DonQuixoteApp.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import SwiftUI

@main
struct DonQuixoteApp: App {
    var body: some Scene {
        WindowGroup { OpenFileView() }
        WindowGroup(id: FileType.ipa.rawValue, for: FileLocation.self, content: IPAView.windowBuilder)
        WindowGroup(id: FileType.macho.rawValue, for: FileLocation.self, content: MachoView.windowBuilder)
        WindowGroup(id: FileType.fat.rawValue, for: FileLocation.self, content: FatBinaryView.windowBuilder)
        WindowGroup(id: FileType.ar.rawValue, for: FileLocation.self, content: UnixArchiveView.windowBuilder)
    }
}
