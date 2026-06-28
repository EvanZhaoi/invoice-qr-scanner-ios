import AVFoundation
import SwiftUI
import UIKit

struct ScannerSheet: View {
    let simulatedData: String
    let onResult: (String) -> Void
    let onCancel: () -> Void
    let onFailure: (String) -> Void

    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var manualQRCode = ""

    var body: some View {
        NavigationStack {
            Group {
                switch cameraStatus {
                case .authorized:
                    scannerView
                case .notDetermined:
                    permissionView
                case .denied, .restricted:
                    cameraUnavailableView
                @unknown default:
                    cameraUnavailableView
                }
            }
            .navigationTitle("扫描二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }
            }
            .task {
                await refreshCameraPermission()
            }
        }
    }

    private var scannerView: some View {
        ZStack {
            NativeQRCodeScannerView(
                onCodeScanned: { code in
                    let value = code.trimmingCharacters(in: .whitespacesAndNewlines)
                    if value.isEmpty {
                        onFailure("扫描到的二维码内容为空，请重新扫描。")
                    } else {
                        onResult(value)
                    }
                },
                onFailure: onFailure
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white, lineWidth: 3)
                    .frame(width: 250, height: 250)
                    .overlay {
                        Text("对准发票二维码")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .padding(.top, 286)
                    }

                Spacer()

                Button {
                    onResult(simulatedData)
                } label: {
                    Text("使用 mock 数据测试")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color.black)
    }

    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("需要摄像头权限")
                .font(.title3.bold())

            Text("授权后才能扫描发票二维码。")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("授权摄像头") {
                Task {
                    await requestCameraPermission()
                }
            }
            .buttonStyle(.borderedProminent)

            fallbackControls
        }
        .padding(24)
    }

    private var cameraUnavailableView: some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("摄像头不可用")
                .font(.title3.bold())

            Text("请在系统设置中允许本 App 使用摄像头，或者先使用 mock 数据测试。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("打开系统设置") {
                openAppSettings()
            }
            .buttonStyle(.borderedProminent)

            fallbackControls
        }
        .padding(24)
    }

    private var fallbackControls: some View {
        VStack(spacing: 12) {
            Button("使用 mock 数据测试") {
                onResult(simulatedData)
            }
            .buttonStyle(.bordered)

            TextField("手动粘贴二维码内容", text: $manualQRCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            Button("提交手动内容") {
                let value = manualQRCode.trimmingCharacters(in: .whitespacesAndNewlines)
                if value.isEmpty {
                    onFailure("手动输入的二维码内容为空。")
                } else {
                    onResult(value)
                }
            }
            .disabled(manualQRCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.top, 10)
    }

    @MainActor
    private func refreshCameraPermission() async {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .notDetermined {
            await requestCameraPermission()
        }
    }

    @MainActor
    private func requestCameraPermission() async {
        let granted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
        cameraStatus = granted ? .authorized : AVCaptureDevice.authorizationStatus(for: .video)
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(settingsURL)
    }
}

private struct NativeQRCodeScannerView: UIViewRepresentable {
    let onCodeScanned: (String) -> Void
    let onFailure: (String) -> Void

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        context.coordinator.configureSession(for: view)
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned, onFailure: onFailure)
    }

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let onCodeScanned: (String) -> Void
        private let onFailure: (String) -> Void
        private var didScanCode = false

        init(
            onCodeScanned: @escaping (String) -> Void,
            onFailure: @escaping (String) -> Void
        ) {
            self.onCodeScanned = onCodeScanned
            self.onFailure = onFailure
        }

        func configureSession(for view: ScannerPreviewView) {
            guard let captureDevice = AVCaptureDevice.default(for: .video) else {
                onFailure("当前设备没有可用摄像头。")
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                let output = AVCaptureMetadataOutput()

                guard session.canAddInput(input), session.canAddOutput(output) else {
                    onFailure("无法初始化扫码会话。")
                    return
                }

                session.addInput(input)
                session.addOutput(output)

                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                output.metadataObjectTypes = [.qr]

                view.videoPreviewLayer.session = session
                view.videoPreviewLayer.videoGravity = .resizeAspectFill

                DispatchQueue.global(qos: .userInitiated).async { [session] in
                    session.startRunning()
                }
            } catch {
                onFailure("无法启动摄像头：\(error.localizedDescription)")
            }
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard didScanCode == false else {
                return
            }

            guard
                let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                metadataObject.type == .qr,
                let code = metadataObject.stringValue
            else {
                return
            }

            didScanCode = true
            session.stopRunning()
            onCodeScanned(code)
        }
    }
}

private final class ScannerPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
