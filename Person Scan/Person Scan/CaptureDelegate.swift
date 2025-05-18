//
//  CaptureDelegate.swift
//  Person Scan
//
//  Created by Enes Eken on 17.05.2025.
//

import AVFoundation
import UIKit
import Vision

class CaptureDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    @Published var peopleCount: Int = 0
    @Published var detectedRectangles: [CGRect] = []
    @Published var uniqueFaces: [UIImage] = []

    private let ciContext = CIContext()
    private var lastDetectionTime = Date()
    private let faceScanDelay: TimeInterval = 1.0
    private let maxStoredFaces = 15

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let bodyDetection = VNDetectHumanRectanglesRequest { req, err in
            if let err = err {
                print("Human detection failed: \(err.localizedDescription)")
                return
            }
            guard let results = req.results as? [VNHumanObservation] else { return }

            DispatchQueue.main.async {
                self.peopleCount = results.count
                self.detectedRectangles = results.map { $0.boundingBox }
            }
        }

        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) > faceScanDelay else {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([bodyDetection])
            return
        }
        lastDetectionTime = now

        let faceDetection = VNDetectFaceRectanglesRequest { [weak self] req, err in
            guard let self = self else { return }
            if let err = err {
                print("Face detection failed: \(err.localizedDescription)")
                return
            }
            guard let faces = req.results as? [VNFaceObservation],
                  let sourceImage = self.extractUIImage(from: pixelBuffer) else { return }

            var freshFaces: [UIImage] = []

            for observation in faces {
                if let faceImage = self.cropFace(from: sourceImage, boundingBox: observation.boundingBox) {
                    freshFaces.append(faceImage)
                }
            }

            DispatchQueue.main.async {
                for newFace in freshFaces {
                    if self.uniqueFaces.count >= self.maxStoredFaces { break }
                    if !self.uniqueFaces.contains(where: { self.imagesLookSimilar($0, newFace) }) {
                        self.uniqueFaces.append(newFace)
                    }
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([bodyDetection, faceDetection])
        } catch {
            print("Request error: \(error.localizedDescription)")
        }
    }

    private func extractUIImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func cropFace(from image: UIImage, boundingBox: CGRect) -> UIImage? {
        let imgWidth = image.size.width
        let imgHeight = image.size.height

        let cropRect = CGRect(
            x: boundingBox.origin.x * imgWidth,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imgHeight,
            width: boundingBox.width * imgWidth,
            height: boundingBox.height * imgHeight
        ).integral

        guard let cgImage = image.cgImage,
              let faceCrop = cgImage.cropping(to: cropRect) else { return nil }

        return UIImage(cgImage: faceCrop, scale: image.scale, orientation: .up)
    }

    private func imagesLookSimilar(_ imgA: UIImage, _ imgB: UIImage) -> Bool {
        let thumbnailA = imgA.resized(to: CGSize(width: 16, height: 16))
        let thumbnailB = imgB.resized(to: CGSize(width: 16, height: 16))
        guard let dataA = thumbnailA.pngData(), let dataB = thumbnailB.pngData() else { return false }
        return dataA == dataB
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaled ?? self
    }
}
