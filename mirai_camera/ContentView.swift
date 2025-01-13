//
//  ContentView.swift
//  mirai_camera
//
//  Created by Susumu Hoshikawa on 2025/01/11.
//

import SwiftUI
import AVFAudio

struct ContentView: View {
    
    @StateObject private var cameraManager = CameraManager()
    @State private var isSpeaking = false
    @State private var audioPlayer: AVAudioPlayer? // AVAudioPlayerのインスタンスを保持

    
    var body: some View {
        ZStack {
            // カメラ映像を背景に表示.
            CameraView(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
            
            // 検出された矩形をオーバーレイ.
            if let rect = cameraManager.detectedRect {
                Rectangle()
                    .stroke(Color.green, lineWidth: 4.0)
                    .cornerRadius(2.0)
                    .frame(width: rect.width, height: rect.height)
                    .position(x:rect.midX, y: rect.midY)
            }
            
            VStack {
                Spacer()
                
                // 検出結果の表示.
                if let detectedText = cameraManager.detectedText {
                    Text("検出された文字列: \(detectedText)")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundStyle(.white)
                        .cornerRadius(8.0)
                }
                
                // 読み上げボタン.
                Button {
                    if let detectedText = cameraManager.detectedText {
                        speakText(detectedText)
                    }
                } label: {
                    Text("読み上げ")
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8.0)
                }
                .padding()
                .disabled(isSpeaking)
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private func speakText(_ text: String) {
        isSpeaking = true
        let audioFiles = text.map { "\($0).mp3" } // 各文字に対応する音声ファイル名
        
        // 非同期で再生処理を行う
        DispatchQueue.global(qos: .userInitiated).async {
            for file in audioFiles {
                if let url = Bundle.main.url(forResource: file, withExtension: nil) {
                    DispatchQueue.main.async {
                        do {
                            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                            self.audioPlayer?.play()
                        } catch {
                            print("音声ファイルの再生に失敗しました: \(error)")
                        }
                    }
                    // 再生が完了するまで待機
                    while self.audioPlayer?.isPlaying == true {
                        usleep(100_000) // 0.1秒待機
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isSpeaking = false
            }
        }
    }
}

#Preview {
    ContentView()
}
