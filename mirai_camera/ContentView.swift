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
    @State private var currentCharacter: String = "mirai000"

    var body: some View {
        ZStack {
            // カメラ映像を背景に表示.
            CameraView(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
            
            // 検出された矩形をオーバーレイ.
            if let rect = cameraManager.detectedRect {
                let expandedRect = rect.insetBy(dx: -10, dy: -10) // 矩形を拡張
                
                OverlayRect(
                    rect: expandedRect,
                    borderColor: .accentColor,
                    fillColor: .accentColor.opacity(0.3)
                )
            }
            
            VStack {
                Spacer()
                
                HStack {
                    // 読み上げボタン.
                    Button {
                        if let detectedText = cameraManager.detectedText {
                            speakText(detectedText.lowercased())
                        }
                    } label: {
                        Image(currentCharacter)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200)
                    }
                    .disabled(isSpeaking)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            cameraManager.startSession()
            preloadAudioFiles() // 画面が表示されたタイミングで音声ファイルをロード
            
            // 初期値をランダムに設定
            currentCharacter = generateRandomCharacterImage()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .ignoresSafeArea()
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
                        currentCharacter = String(char)
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
                currentCharacter = generateRandomCharacterImage() // ランダムなデフォルト画像に設定
            }
        }
    }
    
    /// ランダムな画像名を生成する関数
    private func generateRandomCharacterImage() -> String {
        let randomIndex = Int.random(in: 0...7)
        return String(format: "mirai%03d", randomIndex)
    }
}
