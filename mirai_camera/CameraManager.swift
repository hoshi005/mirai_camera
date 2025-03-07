//
//  CameraManager.swift
//  mirai_camera
//
//  Created by Susumu Hoshikawa on 2025/01/11.
//

import AVFoundation
import Vision

class CameraManager: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var detectedText: String? // 検出された文字列.
    @Published var detectedRect: CGRect? // 矩形情報.
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "mirai_camera.queue")
    private let textRecognitionRequest = VNRecognizeTextRequest()
    
    // ホワイトリスト（許可する文字列）
    private let whitelist: [String] = [
        "5g3dwf9yrtwk",
        "5g2zkuukucws",
        "6pef947898",
        "59m4d3e594",
        "fvs7647587",
        "happybirthday",
        "hey",
        "01.25",
        "0125",
    ]
    
    override init() {
        super.init()
        setupCamera()
        setupTextRecognition()
    }
    
    private func setupCamera() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            fatalError("Failed to get video device")
        }
        
        captureSession.beginConfiguration()
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        captureSession.commitConfiguration()
        
        // プレビュー設定
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        
    }
    
    private func setupTextRecognition() {
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = false
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }
}


extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([textRecognitionRequest])
            if let results = textRecognitionRequest.results {
                processTextObservations(results)
            }
        } catch {
            print("OCR処理中にエラー: \(error)")
        }
    }
    
    private func processTextObservations(_ observations: [VNRecognizedTextObservation]) {
        var isMatchFound = false // ホワイトリストに一致したかを追跡

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first?.string else { continue }
            let filteredText = candidate.filter { $0.isLetter || $0.isNumber }
            
            // ホワイトリストとの比較（大文字小文字を区別しない）
            let lowercasedWhitelist = whitelist.map { $0.lowercased() }
            let lowercasedText = filteredText.lowercased()
            
            if lowercasedWhitelist.contains(lowercasedText), let previewLayer = self.previewLayer {
                isMatchFound = true // 一致が見つかった場合にフラグを設定
                DispatchQueue.main.async {
                    // 正規化された座標を変換
                    let boundingBox = observation.boundingBox
                    let convertedRect = previewLayer.layerRectConverted(fromMetadataOutputRect: boundingBox)
                    
                    // 水平方向の反転を補正
                    let mirroredRect = CGRect(
                        x: previewLayer.bounds.width - convertedRect.maxX,
                        y: convertedRect.origin.y,
                        width: convertedRect.width,
                        height: convertedRect.height
                    )
                    
                    self.detectedText = filteredText
                    self.detectedRect = mirroredRect
                }
                break
            }
        }
        
        // 一致する文字列が見つからなかった場合、矩形と文字列をクリア
        if !isMatchFound {
            DispatchQueue.main.async {
                self.detectedText = nil
                self.detectedRect = nil
            }
        }
    }
}
