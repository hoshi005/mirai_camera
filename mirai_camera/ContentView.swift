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
    @State private var audioPlayers: [String: AVAudioPlayer] = [:] // 音声ファイルを保持する辞書型
    
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
                    .position(x: rect.midX, y: rect.midY)
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
                        speakText(detectedText.lowercased())
                    }
                } label: {
                    Text("未来衣ちゃんが読み上げるぞ！")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(8.0)
                }
                .padding()
                .disabled(isSpeaking)
            }
        }
        .onAppear {
            cameraManager.startSession()
            preloadAudioFiles() // 画面が表示されたタイミングで音声ファイルをロード
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private func preloadAudioFiles() {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".lowercased()
        for char in characters {
            let fileName = "\(char).mp3"
            if let url = Bundle.main.url(forResource: fileName, withExtension: nil) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay() // 再生準備を行う
                    audioPlayers[String(char)] = player
                } catch {
                    print("音声ファイルのロードに失敗しました: \(fileName), \(error)")
                }
            } else {
                print("音声ファイルが見つかりません: \(fileName)")
            }
        }
    }
    
    private func speakText(_ text: String) {
        isSpeaking = true
        DispatchQueue.global(qos: .userInitiated).async {
            for char in text {
                if let player = audioPlayers[String(char)] {
                    DispatchQueue.main.sync {
                        player.play()
                    }
                    // 再生が完了するまで待機
                    while player.isPlaying {
                        usleep(1_000) // 0.05秒待機
                    }
                }
            }
            DispatchQueue.main.async {
                isSpeaking = false // 再生完了後にボタンを有効化
            }
        }
    }
}
