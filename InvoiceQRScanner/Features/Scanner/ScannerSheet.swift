import AVFoundation
import CodeScanner
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
            ZStack {
                Color.black.ignoresSafeArea()

                switch cameraStatus {
                case .authorized:
                    scanner
                case .notDetermined:
                    permissionRequestView
                case .denied, .restricted:
                    unavailableCameraView(
                        title: "无法使用摄像头",
                        message: "请在系统设置中允许本 App 使用摄像头，或先使用 mock 数据完成测试。"
                    )
                @unknown default:
                    unavailableCameraView(
                        title: "摄像头状态异常",
                        message: "当前设备返回了未知权限状态，请使用 mock 数据或手动输入二维码内容。"
                    )
                }
            }
            .navigationTitle("扫描发票二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        onCancel()
                    }
                    .foregroundStyle(.white)
                }
            }
            .task {
                await refreshCameraPermissionIfNeeded()
            }
        }
    }

    private var scanner: some View {
        ZStack {
            CodeScannerView(
                codeTypes: [.qr],
                scanMode: .once,
                showViewfinder: false,
                simulatedData: simulatedData,
                shouldVibrateOnSuccess: true
            ) { result in
                switch result {
                case .success(let scanResult):
                    let value = scanResult.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if value.isEmpty {
                        onFailure("扫描到的二维码内容为空，请重新扫描。")
                    } else {
                        onResult(value)
                    }
                case .failure(let error):
                    onFailure("扫码组件返回错误：\(String(describing: error))。可以检查摄像头权限，或使用 mock 数据测试。")
                }
            }
            .ignoresSafeArea()

            scannerOverlay
        }
    }

    private var scannerOverlay: some View {
        VStack(spacing: 0) {
            Text("将发票二维码放入取景框")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 18)

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(.white.opacity(0.88), lineWidth: 3)
                    .frame(width: 270, height: 270)

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color.green.opacity(0.55), lineWidth: 10)
                    .frame(width: 270, height: 270)
                    .blur(radius: 16)

                Image(systemName: "qrcode")
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(.white.opacity(0.16))
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onResult(simulatedData)
                } label: {
                    Label("使用 mock 数据", systemImage: "wand.and.stars")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.black.opacity(0.86))
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("如果是真机测试，请确认系统已授权摄像头。Simulator 建议直接用 mock 数据。")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(20)
            .background(.black.opacity(0.42))
        }
    }

    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.white)

            Text("需要摄像头权限")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("点击下方按钮授权后，即可扫描发票二维码。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))

            Button {
                Task {
                    await requestCameraPermission()
                }
            } label: {
                Text("授权摄像头")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black.opacity(0.86))
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            fallbackControls
        }
        .padding(24)
    }

    private func unavailableCameraView(title: String, message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.white)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))

            Button {
                openAppSettings()
            } label: {
                Label("打开系统设置", systemImage: "gearshape.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black.opacity(0.86))
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            fallbackControls
        }
        .padding(24)
    }

    private var fallbackControls: some View {
        VStack(spacing: 12) {
            Button {
                onResult(simulatedData)
            } label: {
                Label("使用 mock 数据测试", systemImage: "wand.and.stars")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(.white.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            TextField("手动粘贴二维码内容", text: $manualQRCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                let value = manualQRCode.trimmingCharacters(in: .whitespacesAndNewlines)
                if value.isEmpty {
                    onFailure("手动输入的二维码内容为空。")
                } else {
                    onResult(value)
                }
            } label: {
                Text("提交手动输入内容")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black.opacity(0.86))
            .background(Color.green.opacity(manualQRCode.isEmpty ? 0.42 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(manualQRCode.isEmpty)
        }
        .padding(.top, 8)
    }

    @MainActor
    private func refreshCameraPermissionIfNeeded() async {
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
