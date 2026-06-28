import Foundation

struct InvoiceAPIResponse: Identifiable, Equatable {
    let id = UUID()
    let invoiceCode: String
    let invoiceNumber: String
    let amount: Decimal
    let status: String
    let message: String

    var displayText: String {
        """
        发票代码：\(invoiceCode)
        发票号码：\(invoiceNumber)
        金额：¥\(amount.description)
        状态：\(status)
        说明：\(message)
        """
    }
}

