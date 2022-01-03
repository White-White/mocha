//
//  ContentView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/5.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class OpenPanelDelegate: NSObject, NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        
        if let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey]) {
            if let isDirectory = resourceValues.isDirectory,
                isDirectory {
                return true
            }
            
            if let isRegularFile = resourceValues.isRegularFile,
                !isRegularFile {
                return false
            }
        }
        
        let fileHandle = FileHandle(forReadingAtPath: url.path)
        if let magicData = try? fileHandle?.read(upToCount: 8),
            let _ = MagicType(DataSlice(magicData)) {
            return true
        }
        
        return false
    }
}

struct ContentView: View {
    
    @State private var fileURL: URL?
    let openPanelDelegate = OpenPanelDelegate()
    
    var body: some View {
        if let fileURL = fileURL, let file = try? File(with: fileURL) {
            FileView(file: file).navigationTitle(fileURL.absoluteString)
        } else {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Select File") {
                        let openPanel = NSOpenPanel()
                        openPanel.treatsFilePackagesAsDirectories = true
                        openPanel.allowsMultipleSelection = false
                        openPanel.canChooseDirectories = false
                        openPanel.canCreateDirectories = false
                        openPanel.canChooseFiles = true
                        openPanel.delegate = self.openPanelDelegate
                        openPanel.begin {
                            if $0 == .OK {
                                self.fileURL = openPanel.url
                            }
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
}
