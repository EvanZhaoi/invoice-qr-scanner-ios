import Foundation

protocol InvoiceAPIClient {
    func verifyInvoice(qrCode: String) async throws -> InvoiceAPIResponse
}

enum InvoiceAPIError: LocalizedError {
    case emptyQRCode
    case invalidServerResponse

    var errorDescription: String? {
        switch self {
        case .emptyQRCode:
            return "二维码内容为空，无法提交。"
        case .invalidServerResponse:
            return "接口返回格式不正确。"
        }
    }
}

struct MockInvoiceAPIClient: InvoiceAPIClient {
    func verifyInvoice(qrCode: String) async throws -> InvoiceAPIResponse {
        let trimmedQRCode = qrCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQRCode.isEmpty == false else {
            throw InvoiceAPIError.emptyQRCode
        }

        try await Task.sleep(nanoseconds: 700_000_000)

        return InvoiceAPIResponse(
            invoiceCode: "044002600111",
            invoiceNumber: "52749318",
            amount: Decimal(string: "128.50") ?? 128.50,
            status: "验真通过",
            message: "mock API 已收到二维码参数：\(trimmedQRCode)"
        )
    }
}

struct URLSessionInvoiceAPIClient: InvoiceAPIClient {
    let endpoint: URL
    let session: URLSession

    init(
        endpoint: URL,
        session: URLSession = .shared
    ) {
        self.endpoint = endpoint
        self.session = session
    }

    func verifyInvoice(qrCode: String) async throws -> InvoiceAPIResponse {
        let trimmedQRCode = qrCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQRCode.isEmpty == false else {
            throw InvoiceAPIError.emptyQRCode
        }

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "qrCode", value: trimmedQRCode)
        ]

        guard let url = components?.url else {
            throw InvoiceAPIError.invalidServerResponse
        }

        let (data, _) = try await session.data(from: url)
        let dto = try JSONDecoder().decode(InvoiceAPIResponseDTO.self, from: data)
        return dto.toDomain()
    }
}

private struct InvoiceAPIResponseDTO: Decodable {
    let invoiceCode: String
    let invoiceNumber: String
    let amount: Decimal
    let status: String
    let message: String

    func toDomain() -> InvoiceAPIResponse {
        InvoiceAPIResponse(
            invoiceCode: invoiceCode,
            invoiceNumber: invoiceNumber,
            amount: amount,
            status: status,
            message: message
        )
    }
}

