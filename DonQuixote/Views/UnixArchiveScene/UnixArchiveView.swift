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
        MachoContainerView(mainFileLocation: unixArchive.location, machoFileLocations: unixArchive.machoLocations)
    }
    
    init(_ unixArchive: UnixArchive) {
        self.unixArchive = unixArchive
    }
    
}
