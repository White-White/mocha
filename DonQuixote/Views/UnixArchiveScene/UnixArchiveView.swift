//
//  UnixArchiveView.swift
//  DonQuixote
//
//  Created by white on 2023/8/1.
//

import Foundation
import SwiftUI

struct UnixArchiveView: DocumentView {
    
    let unixArchive: UnixArchive
    
    var body: some View {
        List(unixArchive.machoLocations, id: \.fileName) { machoLocation in
            MachoItemView(machoLocation: machoLocation)
        }
    }
    
    init(_ unixArchive: UnixArchive) {
        self.unixArchive = unixArchive
    }
    
}
