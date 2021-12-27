//
//  ContentView.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/5.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    
    @State private var fileURL: URL?
    @State private var isImporting: Bool = false
    
    var body: some View {
        if let fileURL = fileURL, let file = try? File(with: fileURL) {
            FileView(file: file).navigationTitle(fileURL.absoluteString)
        } else {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Select File") { self.isImporting = true }
                    Spacer()
                }
                Spacer()
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.framework, .archive, .unixExecutable, UTType(filenameExtension: "a")!],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile: URL = try result.get().first else { return }
                    self.fileURL = selectedFile
                } catch {
                    // Handle failure.
                    print("Unable to read file contents")
                    print(error.localizedDescription)
                }
            }
        }
    }
    
}
