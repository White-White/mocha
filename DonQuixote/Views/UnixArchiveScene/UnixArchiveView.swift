//
//  UnixArchiveView.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import Foundation
import SwiftUI

struct UnixArchiveHeaderView: View {
    
    let machoFileLocation: FileLocation
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("file name: \(machoFileLocation.fileName)")
                Text("file size: \(machoFileLocation.size) bytes")
                Spacer()
                    .frame(height: 0)
                    .frame(maxWidth: .infinity)
            }
            Button("Open", action: self.action)
        }
        .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .border(.separator, width: 1)
        .background(.white)
        .frame(minWidth: 600)
    }
    
}

struct UnixArchiveView: DocumentView {
    
    @Environment (\.openWindow) var openWindow
    let unixArchive: UnixArchive
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(unixArchive.machoFileLocations, id: \.fileName) { machoFileLocation in
                    UnixArchiveHeaderView(machoFileLocation: machoFileLocation) {
                        openWindow(id: FileType.unixExecutable.rawValue, value: machoFileLocation)
                    }
                }
                Spacer()
            }
        }
    }
    
    init(_ unixArchive: UnixArchive) {
        self.unixArchive = unixArchive
    }
    
}
