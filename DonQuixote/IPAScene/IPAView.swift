//
//  IPAView.swift
//  DonQuixote
//
//  Created by white on 2023/6/25.
//

import Foundation
import SwiftUI

struct IPAView: View {
    
    let ipa: IPA
    
    var body: some View {
        Button("Start Faking") {
            try! Faking.run(for: ipa)
        }
    }
    
}
