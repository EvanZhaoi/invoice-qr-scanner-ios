import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = InvoiceScannerViewModel()
    @State private var isShowingScanner = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroSection
                        primaryScanCard
                        processCard
                        lastResultCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("发票验真")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $isShowingScanner) {
                ScannerSheet(
                    simulatedData: viewModel.simulatedQRCode,
                    onResult: { scannedText in
                        isShowingScanner = false
                        Task {
                            await viewModel.submit(scannedQRCode: scannedText)
                        }
                    },
                    onCancel: {
                        isShowingScanner = false
                    },
                    onFailure: { message in
                        isShowingScanner = false
                        viewModel.showScannerError(message)
                    }
                )
            }
            .alert("接口返回结果", isPresented: $viewModel.isShowingResultAlert) {
                Button("完成", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .alert("无法扫描", isPresented: $viewModel.isShowingErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invoice QR")
                        .font(.caption.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(AppTheme.accent)

                    Text("扫描发票二维码\n快速获取校验结果")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                }

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 62, height: 62)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            Text("扫码后，系统会把二维码原文作为参数提交给 mock API，并将返回值以弹窗展示。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryScanCard: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.16))
                    .frame(width: 148, height: 148)

                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(.white.opacity(0.24), lineWidth: 1)
                    .frame(width: 116, height: 116)

                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 70, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("发票二维码识别")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text("对准发票右上角或电子发票中的二维码")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.68))
            }

            Button {
                isShowingScanner = true
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "camera.viewfinder")
                    }

                    Text(viewModel.isLoading ? "正在提交..." : "开始扫描")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(AppTheme.buttonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.accent.opacity(0.32), radius: 18, x: 0, y: 10)
            .disabled(viewModel.isLoading)

            Button {
                Task {
                    await viewModel.submit(scannedQRCode: viewModel.simulatedQRCode)
                }
            } label: {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("使用 mock 数据演示")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.92))
            .background(.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .disabled(viewModel.isLoading)
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 28, x: 0, y: 18)
    }

    private var processCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("处理流程")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                ProcessStep(index: "1", title: "扫码", icon: "qrcode")
                ProcessStep(index: "2", title: "提交", icon: "paperplane.fill")
                ProcessStep(index: "3", title: "展示", icon: "text.bubble.fill")
            }
        }
        .padding(18)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var lastResultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("最近一次扫码", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                if viewModel.lastScannedQRCode != nil {
                    Text("已记录")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.accent.opacity(0.16))
                        .clipShape(Capsule())
                }
            }

            Text(viewModel.lastScannedQRCode ?? "暂无扫码记录。可以先点击 mock 数据演示完整流程。")
                .font(.footnote.monospaced())
                .foregroundStyle(.white.opacity(0.76))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(18)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct ProcessStep: View {
    let index: String
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 9) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(index)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.black.opacity(0.82))
                    .frame(width: 19, height: 19)
                    .background(AppTheme.accent)
                    .clipShape(Circle())
                    .offset(x: 5, y: -5)
            }

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.84))
        }
        .frame(maxWidth: .infinity)
    }
}

private enum AppTheme {
    static let accent = Color(red: 0.48, green: 0.96, blue: 0.78)

    static let background = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.06, blue: 0.13),
            Color(red: 0.06, green: 0.18, blue: 0.28),
            Color(red: 0.04, green: 0.36, blue: 0.42)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonGradient = LinearGradient(
        colors: [
            Color(red: 0.09, green: 0.65, blue: 0.80),
            Color(red: 0.18, green: 0.80, blue: 0.55)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cardBackground = LinearGradient(
        colors: [
            .white.opacity(0.18),
            .white.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

#Preview {
    ContentView()
}
