//
//  ContentView.swift
//  Person Scan
//
//  Created by Enes Eken on 17.05.2025.
//

import AVFoundation
import SwiftUI
import Vision

struct ContentView: View {
    @State private var peopleCount: Int = 0
    @State private var isCameraFeed: Bool = false
    @State private var detectedRectangles: [CGRect] = []
    @StateObject private var captureDelegate = CaptureDelegate()

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        VStack {
            if !isCameraFeed {
                VStack(spacing: 20) {
                    Spacer()

                    Text("The Person Scan app uses the camera for human detection.")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .statusBarHidden(true)
                .background(Color("Color_Gray"))
                .edgesIgnoringSafeArea(.all)
                
            } else {
                ScrollView {
                    HStack {
                        Spacer()
                        VStack(alignment: .center) {
                            Text("Detected People")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(captureDelegate.peopleCount)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(width: 300)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 5)
                        Spacer()
                    }
                    .padding(.horizontal)

                    HumanDetectionInCameraFeed(captureDelegate: captureDelegate)
                        .frame(height: 330)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        .padding(.top)

                    if !captureDelegate.uniqueFaces.isEmpty {
                        Text("Faces Detected in the Photo")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                            .padding(.top, 25)

                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(captureDelegate.uniqueFaces, id: \.self) { face in
                                Image(uiImage: face)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 5)
                                    .rotationEffect(.degrees(90))
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 5)
                        .padding()
                    }
                    Spacer()
                }
                .scrollIndicators(.hidden)
                .background(Color("Color_Gray"))
                .edgesIgnoringSafeArea(.bottom)
                .statusBarHidden(true)
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraFeed = true

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isCameraFeed = granted
                }
            }

        case .denied, .restricted:
            isCameraFeed = false

        @unknown default:
            isCameraFeed = false
        }
    }
}

#Preview {
    ContentView()
}
