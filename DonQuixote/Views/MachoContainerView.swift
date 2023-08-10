//
//  MachoContainerView.swift
//  DonQuixote
//
//  Created by white on 2023/8/10.
//

import SwiftUI

struct MachoContainerView: View {
    
    let mainFileLocation: FileLocation
    let machoFileLocations: [FileLocation]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("File path:").bold()
                Text(mainFileLocation.fileURL.relativePath)
                Button("Show in Finder") {
                    NSWorkspace.shared.open(
                        URL(
                            fileURLWithPath: mainFileLocation.fileURL.deletingLastPathComponent().path(),
                            isDirectory: true
                        )
                    )
                }
            }
            HStack {
                Text("File type:").bold()
                Text(mainFileLocation.fileType.name)
                    .padding(.bottom, 4)
            }
            List(self.machoFileLocations, id: \.fileOffset) { machoFileLocation in
                MachoItemView(machoLocation: machoFileLocation)
            }
        }
        .padding(16)
        .background(.white)
    }
    
}
