//
//  HexadecimalLineView.swift
//  mocha (macOS)
//
//  Created by white on 2022/6/30.
//

import SwiftUI

struct HexadecimalLineView: View {
    
    @ObservedObject var viewModel: HexadecimalLineViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(viewModel.offsetString)
                .background(Color(.sRGB, red: 228/255, green: 228/255, blue: 228/255, opacity: 1))
                .font(.system(size: 14).monospaced())
                .foregroundColor(.secondary)
            Text(viewModel.attributedHexadecimalString)
                .textSelection(.enabled)
                .padding(.leading, 4)
        }
    }
    
}
