//
//  DocumentView.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import Foundation
import SwiftUI

protocol DocumentView: View {
    associatedtype Content: View
    associatedtype D: Document
    init(_ d: D)
    static func windowBuilder(_ fileLocation: Binding<FileLocation?>) -> Content
}

extension DocumentView {
    static func windowBuilder(_ fileLocation: Binding<FileLocation?>) -> some View {
        DocumentViewWrapper<Self>(fileLocation: fileLocation.wrappedValue)
    }
}

struct DocumentViewWrapper<V: DocumentView>: View {
    
    @Environment (\.dismiss) var dismiss
    let result: Result<V, Error>
    
    var body: some View {
        VStack {
            switch result {
            case .success(let documentView):
                documentView
            case .failure(let error):
                VStack {
                    Text("\(error.localizedDescription)")
                    Button("Dismiss") {
                        self.dismiss()
                    }
                }
            }
        }
        .navigationTitle(self.navigationTitle)
    }
    
    let navigationTitle: String
    
    init(fileLocation: FileLocation?) {
        guard let fileLocation else {
            let error = DonError.invalidFileLocation
            self.result = .failure(error)
            self.navigationTitle = error.localizedDescription
            return
        }
        do {
            let document = try V.D.init(with: fileLocation)
            let documentView = V.init(document)
            self.result = .success(documentView)
            self.navigationTitle = fileLocation.fileName
        } catch let error {
            self.result = .failure(error)
            self.navigationTitle = error.localizedDescription
        }
    }
    
}
