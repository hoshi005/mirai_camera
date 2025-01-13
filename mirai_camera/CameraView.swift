//
//  CameraView.swift
//  mirai_camera
//
//  Created by Susumu Hoshikawa on 2025/01/11.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        // プレビューを追加.
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = UIScreen.main.bounds
            viewController.view.layer.addSublayer(previewLayer)
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
