//
//  SpeechBubble.swift
//  mirai_camera
//
//  Created by Susumu Hoshikawa on 2025/01/25.
//

import SwiftUI

struct SpeechBubble: View {
    let text: String // 表示する文字
    @State private var bubbleImageName: String = ""

    var body: some View {
        ZStack {
            // 背景画像
            Image(bubbleImageName)
                .resizable()
                .scaledToFit()
            
            // テキスト
            Text(text)
                .font(.system(size: 40))
                .bold()
                .foregroundColor(.white)
                .offset(y: -6) // テキストの位置を中央よりやや上に調整
        }
        .onAppear {
            bubbleImageName = generateRandomBubbleImageName() // ランダム画像名を生成
        }
    }
    
    /// ランダムな吹き出し画像名を生成する関数
    private func generateRandomBubbleImageName() -> String {
        let randomIndex = Int.random(in: 1...6) // 1〜6のランダム値
        return String(format: "%03d", randomIndex) // ゼロ埋めで画像名生成
    }
}

#Preview {
    SpeechBubble(text: "A")
        .frame(width: 100, height: 100)
}
