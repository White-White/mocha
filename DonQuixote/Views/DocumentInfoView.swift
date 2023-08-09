//
//  DocumentInfoView.swift
//  DonQuixote
//
//  Created by white on 2023/8/9.
//

import SwiftUI

struct DocumentInfoView: View {
    
    let location: FileLocation
    let fileType: FileType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("File path:").bold()
            Text(location.fileURL.relativePath)
            Button("Show in Finder") {
                NSWorkspace.shared.open(
                    URL(
                        fileURLWithPath: location.fileURL.deletingLastPathComponent().path(),
                        isDirectory: true
                    )
                )
            }
            .padding(.bottom, 4)
            
            Text("File type:").bold()
            Text(fileType.name)
                .padding(.bottom, 4)
            
            Text("File size:").bold()
            Text("\(location.fileSize)")
        }
        .padding(16)
    }
    
}
