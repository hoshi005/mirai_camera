//
//  OverlayRect.swift
//  mirai_camera
//
//  Created by Susumu Hoshikawa on 2025/01/15.
//

import SwiftUI

struct OverlayRect: View {
    let rect: CGRect
    let cornerRadius: CGFloat = 8.0
    let borderColor: Color
    let borderWidth: CGFloat = 4.0
    let fillColor: Color

    var body: some View {
        ZStack {
            // 塗りつぶし
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(fillColor)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
            
            // 枠線
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        }
    }
}
