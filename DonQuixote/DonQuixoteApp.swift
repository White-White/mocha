//
//  DonQuixoteApp.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import SwiftUI

struct ErrorView: View {
    
    @Environment (\.dismiss) private var dismiss
    let error: Error
    
    var body: some View {
        VStack {
            Text("\(error.localizedDescription)")
            Button("Dismiss") {
                self.dismiss()
            }
        }
    }
    
}

@main
struct DonQuixoteApp: App {
    
    var body: some Scene {
        
        WindowGroup {
            OpenFileView()
        }
        
        WindowGroup(id: KnownFileType.ipa.rawValue, for: URL.self) { $url in
            switch Document.openIPA(fileURL: url) {
            case .error(let error):
                ErrorView(error: error)
            case .success(let ipa):
                IPAView(ipa: ipa)
            }
        }
        
        WindowGroup(id: KnownFileType.unixExecutable.rawValue, for: URL.self) { $url in
            switch Document.openMacho(fileURL: url) {
            case .error(let error):
                ErrorView(error: error)
            case .success(let macho):
                MachoView(machoViewState: MachoViewState(macho))
            }
        }
        
        WindowGroup(id: KnownFileType.ar.rawValue, for: URL.self) { $url in
            fatalError()
        }
        
    }
    
}
