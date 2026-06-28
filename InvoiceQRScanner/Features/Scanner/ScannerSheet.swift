import CodeScanner
import SwiftUI

struct ScannerSheet: View {
    let simulatedData: String
    let onResult: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            CodeScannerView(
                codeTypes: [.qr],
                scanMode: .once,
                showViewfinder: true,
                simulatedData: simulatedData,
                shouldVibrateOnSuccess: true
            ) { result in
                switch result {
                case .success(let scanResult):
                    onResult(scanResult.string)
                case .failure:
                    onCancel()
                }
            }
            .navigationTitle("扫描发票二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }
            }
        }
    }
}

