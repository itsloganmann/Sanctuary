//
//  QRScannerView.swift
//  Sanctuary
//
//  QR code scanner for partner/contact linking
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var isShowingError = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    
    let purpose: LinkingPurpose
    let onCodeScanned: (String) async throws -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera view
                QRScannerRepresentable(
                    scannedCode: $scannedCode,
                    isProcessing: $isProcessing
                )
                .ignoresSafeArea()
                
                // Overlay
                VStack {
                    Spacer()
                    
                    // Scanning frame
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusLarge)
                        .stroke(Color.safetyOrange, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            // Corner accents
                            GeometryReader { geometry in
                                let size = geometry.size
                                let cornerLength: CGFloat = 30
                                let cornerWidth: CGFloat = 4
                                
                                Path { path in
                                    // Top left
                                    path.move(to: CGPoint(x: 0, y: cornerLength))
                                    path.addLine(to: CGPoint(x: 0, y: 0))
                                    path.addLine(to: CGPoint(x: cornerLength, y: 0))
                                    
                                    // Top right
                                    path.move(to: CGPoint(x: size.width - cornerLength, y: 0))
                                    path.addLine(to: CGPoint(x: size.width, y: 0))
                                    path.addLine(to: CGPoint(x: size.width, y: cornerLength))
                                    
                                    // Bottom right
                                    path.move(to: CGPoint(x: size.width, y: size.height - cornerLength))
                                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                                    path.addLine(to: CGPoint(x: size.width - cornerLength, y: size.height))
                                    
                                    // Bottom left
                                    path.move(to: CGPoint(x: cornerLength, y: size.height))
                                    path.addLine(to: CGPoint(x: 0, y: size.height))
                                    path.addLine(to: CGPoint(x: 0, y: size.height - cornerLength))
                                }
                                .stroke(Color.safetyOrange, lineWidth: cornerWidth)
                            }
                        )
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: DesignTokens.spacingMedium) {
                        if isProcessing {
                            ProgressView()
                                .tint(.safetyOrange)
                            Text("Processing...")
                                .font(.bodyMedium)
                                .foregroundStyle(.white)
                        } else {
                            Text("Scan Partner's QR Code")
                                .font(.headlineMedium)
                                .foregroundStyle(.white)
                            
                            Text("Position the QR code within the frame")
                                .font(.bodySmall)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
                    .padding(.bottom, DesignTokens.spacingXLarge)
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onChange(of: scannedCode) { _, newValue in
                if let code = newValue {
                    handleScannedCode(code)
                }
            }
            .alert("Error", isPresented: $isShowingError) {
                Button("OK") {
                    scannedCode = nil
                    isProcessing = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        guard !isProcessing else { return }
        isProcessing = true
        
        Task {
            do {
                try await onCodeScanned(code)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            }
        }
    }
}

// MARK: - QR Scanner UIKit Representable

struct QRScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isProcessing: Bool
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        let parent: QRScannerRepresentable
        
        init(_ parent: QRScannerRepresentable) {
            self.parent = parent
        }
        
        func didScanCode(_ code: String) {
            guard !parent.isProcessing else { return }
            parent.scannedCode = code
        }
    }
}

// MARK: - QR Scanner View Controller

protocol QRScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                metadataOutput.metadataObjectTypes = [.qr]
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        } catch {
            print("Failed to setup camera: \(error)")
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        captureSession?.stopRunning()
        delegate?.didScanCode(stringValue)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

// MARK: - QR Code Generator View

struct QRCodeGeneratorView: View {
    let linkingCode: LinkingCode
    @State private var qrImage: UIImage?
    
    var body: some View {
        VStack(spacing: DesignTokens.spacingLarge) {
            Text("Your QR Code")
                .font(.headlineLarge)
                .foregroundStyle(.white)
            
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusMedium))
            } else {
                ProgressView()
                    .frame(width: 200, height: 200)
            }
            
            // Code display
            Text(linkingCode.code)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(.safetyOrange)
                .tracking(8)
            
            // Expiration timer
            if linkingCode.isValid {
                HStack {
                    Image(systemName: "clock")
                    Text("Expires in \(formattedTimeRemaining)")
                }
                .font(.bodySmall)
                .foregroundStyle(.textSecondary)
            } else {
                Text("Code expired")
                    .font(.bodySmall)
                    .foregroundStyle(.statusDanger)
            }
        }
        .padding(DesignTokens.spacingLarge)
        .sanctuaryCard()
        .onAppear {
            generateQRCode()
        }
    }
    
    private var formattedTimeRemaining: String {
        let remaining = Int(linkingCode.timeRemaining)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func generateQRCode() {
        guard let data = "sanctuary://link?code=\(linkingCode.code)".data(using: .utf8) else { return }
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let ciImage = filter?.outputImage else { return }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return }
        
        qrImage = UIImage(cgImage: cgImage)
    }
}

#Preview {
    QRScannerView(purpose: .partnerLink) { code in
        print("Scanned: \(code)")
    }
}
