//
//  UnixArchiveView.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import Foundation
import SwiftUI

struct UnixArchiveHeaderView: View {
    
    let machoLocation: FileLocation
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("file name: \(machoLocation.fileName)")
                Text("file size: \(machoLocation.fileSize) bytes")
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
        List(unixArchive.machoLocations, id: \.fileName) { machoLocation in
            UnixArchiveHeaderView(machoLocation: machoLocation) {
                openWindow(id: machoLocation.fileType.rawValue, value: machoLocation)
            }
        }
    }
    
    init(_ unixArchive: UnixArchive) {
        self.unixArchive = unixArchive
    }
    
}
