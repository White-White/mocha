//
//  MiniMap.swift
//  mocha
//
//  Created by white on 2021/6/24.
//

import SwiftUI

struct MiniMap: View {
    let size: Int
    let start: Int
    let length: Int
    
    var indicatorPosition: (startPercent: CGFloat, lengthPercent: CGFloat, start: Int, length: Int) {
        let lengthPercent = CGFloat(length) / CGFloat(size)
        let startPercent = CGFloat(start) / CGFloat(size)
        return (startPercent, lengthPercent, start, length)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                GeometryReader { geometry in
                    HStack(alignment: .center) {
                        Spacer().frame(width: indicatorPosition.startPercent * geometry.size.width)
                        Color.red.frame(width: max(indicatorPosition.lengthPercent * geometry.size.width, 1))
                        Spacer()
                    }
                }
            }
            .frame(height: 40)
            .border(.separator, width: 1)
            .background(.white)
            
            HStack(alignment: .center) {
                Text(String(format: "File Size: 0x%0X", size))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                if let position = indicatorPosition {
                    Text(String(format: "Selected: 0x%0X - 0x%0X", position.start, position.length))
                        .font(.system(size: 10))
                        .foregroundColor(.black)
                    Text(String(format: "Position: %.4f%% - %.4f%%", position.startPercent * 100, (position.startPercent + position.lengthPercent) * 100))
                        .font(.system(size: 10))
                        .foregroundColor(.black)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))
        }
    }
}