import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = InvoiceScannerViewModel()
    @State private var isShowingScanner = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("发票管理")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(.darkGray))
                    .padding(.top, 86)
                    .padding(.leading, 38)

                Spacer()

                Text(viewModel.homeDisplayText)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.darkGray))
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer()

                Button {
                    isShowingScanner = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.24, green: 0.48, blue: 0.92))
                            .frame(width: 74, height: 74)
                            .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)

                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 42)
                .disabled(viewModel.isLoading)
            }
        }
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
            Button("确定", role: .cancel) { }
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

#Preview {
    ContentView()
}
