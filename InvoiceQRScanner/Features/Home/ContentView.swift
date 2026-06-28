import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = InvoiceScannerViewModel()
    @State private var isShowingScanner = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.16, blue: 0.33),
                        Color(red: 0.05, green: 0.43, blue: 0.56)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    header
                    scanCard
                    historyCard
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("发票扫码")
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
                    }
                )
            }
            .alert("接口返回结果", isPresented: $viewModel.isShowingResultAlert) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .alert("发生错误", isPresented: $viewModel.isShowingErrorAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("扫描发票二维码")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("识别二维码后，应用会把二维码内容作为参数提交到 mock API，并弹窗展示返回结果。")
                .font(.body)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scanCard: some View {
        VStack(spacing: 18) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 68, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 120, height: 120)
                .background(.white.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

            Button {
                isShowingScanner = true
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "camera.viewfinder")
                    }
                    Text(viewModel.isLoading ? "提交中..." : "开始扫描")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(viewModel.isLoading)

            Button {
                Task {
                    await viewModel.submit(scannedQRCode: viewModel.simulatedQRCode)
                }
            } label: {
                Text("使用 mock 二维码测试")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(viewModel.isLoading)
        }
        .padding(22)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("最近一次扫码内容", systemImage: "doc.text.magnifyingglass")
                .font(.headline)
                .foregroundStyle(.white)

            Text(viewModel.lastScannedQRCode ?? "暂无扫码记录")
                .font(.footnote.monospaced())
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.black.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(18)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    ContentView()
}

