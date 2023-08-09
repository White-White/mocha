//
//  OpenFileView.swift
//  DonQuixote
//
//  Created by white on 2023/6/9.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

private class OpenPanelDelegate: NSObject, NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .fileSizeKey]) else {
            return false
        }
        
        if let isDirectory = resourceValues.isDirectory,
           isDirectory {
            return true
        }
        
        if let isRegularFile = resourceValues.isRegularFile,
           !isRegularFile {
            return false
        }
        
        guard let fileSize = resourceValues.fileSize else {
            return false
        }
        
        guard let fileHandle = try? FileHandle(url, fileSize: fileSize, offset: .zero),
              let _ = try? FileType(from: fileHandle) else {
            return false
        }
        
        return true
    }
}

struct OpenFileView: View {
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    private let openPanelDelegate = OpenPanelDelegate()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            Button {
                let openPanel = NSOpenPanel()
                openPanel.treatsFilePackagesAsDirectories = true
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = false
                openPanel.canCreateDirectories = false
                openPanel.canChooseFiles = true
                openPanel.delegate = self.openPanelDelegate
                openPanel.begin {
                    do {
                        if $0 == .OK, let fileURL = openPanel.url {
                            let fileLocation = try FileLocation(fileURL)
                            openWindow(id: fileLocation.fileType.rawValue, value: fileLocation)
                            dismiss()
                        } else {
                            //TODO:
                        }
                    } catch {
                        //TODO:
                    }
                }
            } label: {
                Label("Open File", systemImage: "doc")
            }
        }
        .padding()
    }
}
