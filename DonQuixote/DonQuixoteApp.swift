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
        
        WindowGroup {
            OpenFileView()
        }
        
        WindowGroup(id: KnownFileType.ipa.rawValue, for: URL.self) { $url in
            fatalError()
        }
        
        WindowGroup(id: KnownFileType.unixExecutable.rawValue, for: URL.self) { $url in
            MachoView(url)
        }
        
        WindowGroup(id: KnownFileType.ar.rawValue, for: URL.self) { $url in
            fatalError()
        }
        
    }
}
