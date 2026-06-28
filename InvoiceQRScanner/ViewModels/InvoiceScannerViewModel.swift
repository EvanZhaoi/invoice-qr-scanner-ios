import Foundation

@MainActor
final class InvoiceScannerViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isShowingResultAlert = false
    @Published var isShowingErrorAlert = false
    @Published var alertMessage = ""
    @Published var errorMessage = ""
    @Published var lastScannedQRCode: String?

    let simulatedQRCode = "01,04,044002600111,52749318,128.50,20260628,MOCK-CHECK-CODE"

    private let apiClient: InvoiceAPIClient

    init(apiClient: InvoiceAPIClient = MockInvoiceAPIClient()) {
        self.apiClient = apiClient
    }

    func submit(scannedQRCode: String) async {
        lastScannedQRCode = scannedQRCode
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.verifyInvoice(qrCode: scannedQRCode)
            alertMessage = response.displayText
            isShowingResultAlert = true
        } catch {
            errorMessage = error.localizedDescription
            isShowingErrorAlert = true
        }
    }
}

