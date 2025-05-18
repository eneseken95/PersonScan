//
//  HumanDetectionInCameraFeed.swift
//  Person Scan
//
//  Created by Enes Eken on 17.05.2025.
//

import AVFoundation
import SwiftUI

struct HumanDetectionInCameraFeed: View {
    @ObservedObject var captureDelegate: CaptureDelegate
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "humanCameraQueue")
    @State private var glow: Bool = false

    var body: some View {
        ZStack {
            CameraFeedView(session: session)
                .overlay(overlayRectangles)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                .scaleEffect(glow ? 1.01 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glow)
                .onAppear {
                    glow = true
                    configureSession()
                }
                .onDisappear {
                    stopSession()
                }
        }
    }

    private var overlayRectangles: some View {
        GeometryReader { geometry in
            ForEach(captureDelegate.detectedRectangles.indices, id: \.self) { index in
                
                let rect = captureDelegate.detectedRectangles[index]
                let x = rect.minY * geometry.size.height
                let y = rect.minX * geometry.size.width
                let width = rect.height * geometry.size.height
                let height = rect.width * geometry.size.width

                let scale: CGFloat = 1.2
                let heightScale: CGFloat = 1.5

                let newWidth = width * scale
                let newHeight = height * heightScale

                let newX = x + width / 2 - newWidth / 2
                let newY = y + height / 2 - newHeight / 2

                RoundedRectangle(cornerRadius: 4)
                    .stroke(LinearGradient(
                        colors: [Color(red: 0.60, green: 1.0, blue: 0.77), Color(red: 0.37, green: 0.84, blue: 0.57)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 3)
                    .shadow(color: Color(red: 0.37, green: 0.84, blue: 0.57).opacity(0.5), radius: 10, x: 0, y: 0)
                    .frame(width: newWidth, height: newHeight)
                    .position(x: newX + newWidth / 2, y: newY + newHeight / 2)
                    .opacity(0.85)
                    .transition(.scale)
            }
        }
    }

    private func configureSession() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Camera input error.")
            return
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(captureDelegate, queue: sessionQueue)

        session.beginConfiguration()
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()

        sessionQueue.async { session.startRunning() }
    }

    private func stopSession() {
        session.stopRunning()
    }
}

struct CameraFeedView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = containerView.bounds
        containerView.layer.addSublayer(previewLayer)
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
