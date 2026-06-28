# 发票二维码扫描 iOS 应用开发文档

本文档记录从零开发、运行、接入真实 API、发布到 GitHub 的完整步骤。

## 1. 目标

开发一个 iOS App：

1. 用户点击“开始扫描”。
2. App 打开摄像头扫描发票二维码。
3. 扫描成功后，取到二维码字符串。
4. 将二维码字符串作为参数发送给 API。
5. API 返回发票校验结果。
6. App 用弹窗展示返回结果。

当前作业版本先使用 mock API，保证无后端时也能完整演示流程。

## 2. 技术选型

### 2.1 SwiftUI

用于构建界面。优点是代码量少、状态驱动 UI，适合本作业的扫码、提交、弹窗展示流程。

### 2.2 CodeScanner

CodeScanner 是开源 SwiftUI 扫码组件，提供 `CodeScannerView`。本项目用它完成二维码扫描，避免手写 AVFoundation 摄像头采集和二维码识别逻辑。

依赖地址：

```text
https://github.com/twostraws/CodeScanner
```

### 2.3 XcodeGen

XcodeGen 根据 `project.yml` 生成 `.xcodeproj`，减少手动维护 Xcode 工程文件的成本。

安装：

```bash
brew install xcodegen
```

## 3. 环境准备

1. 安装 macOS。
2. 安装 Xcode 15 或更新版本。
3. 安装 Homebrew。
4. 安装 XcodeGen：

   ```bash
   brew install xcodegen
   ```

5. 克隆或下载本项目。

## 4. 生成并运行工程

在项目根目录执行：

```bash
xcodegen generate
open InvoiceQRScanner.xcodeproj
```

在 Xcode 中：

1. 选择 `InvoiceQRScanner` target。
2. 选择一个 iPhone Simulator 或连接的 iPhone 真机。
3. 点击 Run。

注意：

- 真机扫描需要允许摄像头权限。
- Simulator 不能调用真实摄像头，本项目配置了 `simulatedData`，可以模拟扫码结果。

## 5. 代码结构说明

### 5.1 App 入口

文件：

```text
InvoiceQRScanner/App/InvoiceQRScannerApp.swift
```

作用：

- 声明 SwiftUI App 入口。
- 加载 `ContentView`。

### 5.2 首页

文件：

```text
InvoiceQRScanner/Features/Home/ContentView.swift
```

作用：

- 展示首页 UI。
- 点击“开始扫描”打开扫码 sheet。
- 点击“使用 mock 二维码测试”直接走提交流程。
- 监听 ViewModel 状态并展示成功/失败弹窗。

关键状态：

```swift
@StateObject private var viewModel = InvoiceScannerViewModel()
@State private var isShowingScanner = false
```

### 5.3 扫码页

文件：

```text
InvoiceQRScanner/Features/Scanner/ScannerSheet.swift
```

作用：

- 包装 CodeScanner 的 `CodeScannerView`。
- 只扫描二维码：

  ```swift
  codeTypes: [.qr]
  ```

- 扫描一次后回调二维码字符串：

  ```swift
  onResult(scanResult.string)
  ```

### 5.4 ViewModel

文件：

```text
InvoiceQRScanner/ViewModels/InvoiceScannerViewModel.swift
```

作用：

- 保存页面状态。
- 接收扫码结果。
- 调用 API client。
- 将返回结果格式化为弹窗内容。

核心方法：

```swift
func submit(scannedQRCode: String) async
```

执行流程：

1. 保存最近一次二维码内容。
2. 设置 `isLoading = true`。
3. 调用 `apiClient.verifyInvoice(qrCode:)`。
4. 成功时设置 `alertMessage` 并弹出结果弹窗。
5. 失败时设置 `errorMessage` 并弹出错误弹窗。

### 5.5 API 层

文件：

```text
InvoiceQRScanner/Services/InvoiceAPIClient.swift
```

包含：

- `InvoiceAPIClient` 协议
- `MockInvoiceAPIClient`
- `URLSessionInvoiceAPIClient`

当前默认使用：

```swift
MockInvoiceAPIClient()
```

mock 返回示例：

```swift
InvoiceAPIResponse(
    invoiceCode: "044002600111",
    invoiceNumber: "52749318",
    amount: Decimal(string: "128.50") ?? 128.50,
    status: "验真通过",
    message: "mock API 已收到二维码参数：..."
)
```

## 6. 接入真实 API

假设真实接口是：

```text
GET https://api.example.com/invoice/verify?qrCode=二维码内容
```

步骤：

1. 打开：

   ```text
   InvoiceQRScanner/ViewModels/InvoiceScannerViewModel.swift
   ```

2. 将初始化方法改为注入真实 client：

   ```swift
   init(
       apiClient: InvoiceAPIClient = URLSessionInvoiceAPIClient(
           endpoint: URL(string: "https://api.example.com/invoice/verify")!
       )
   ) {
       self.apiClient = apiClient
   }
   ```

3. 确认后端返回 JSON 字段与 `InvoiceAPIResponseDTO` 一致：

   ```json
   {
     "invoiceCode": "044002600111",
     "invoiceNumber": "52749318",
     "amount": 128.50,
     "status": "验真通过",
     "message": "校验成功"
   }
   ```

4. 如果后端字段名不同，修改 `InvoiceAPIResponseDTO`。

5. 如果后端使用 POST，修改 `URLSessionInvoiceAPIClient.verifyInvoice(qrCode:)`：

   ```swift
   var request = URLRequest(url: endpoint)
   request.httpMethod = "POST"
   request.setValue("application/json", forHTTPHeaderField: "Content-Type")
   request.httpBody = try JSONEncoder().encode(["qrCode": trimmedQRCode])
   let (data, _) = try await session.data(for: request)
   ```

## 7. 摄像头权限

iOS 调用摄像头必须在 `Info.plist` 中声明用途。

文件：

```text
InvoiceQRScanner/Resources/Info.plist
```

配置：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用摄像头扫描发票二维码。</string>
```

## 8. GitHub 发布步骤

如果本地还不是 git 仓库：

```bash
git init
git add .
git commit -m "Initial SwiftUI invoice QR scanner app"
```

在 GitHub 新建仓库，例如：

```text
invoice-qr-scanner-ios
```

添加远端并推送：

```bash
git remote add origin git@github.com:<your-user>/invoice-qr-scanner-ios.git
git branch -M main
git push -u origin main
```

如果已经有 GitHub 远端：

```bash
git add .
git commit -m "Add SwiftUI invoice QR scanner app"
git push
```

## 9. 作业答辩说明

可以按以下顺序演示：

1. 打开 App 首页。
2. 点击“使用 mock 二维码测试”，展示无摄像头时的完整 API 流程。
3. 点击“开始扫描”，展示扫码界面。
4. 说明 Simulator 使用 `simulatedData`；真机可扫描真实二维码。
5. 说明当前 API 是 mock，实现位于 `MockInvoiceAPIClient`。
6. 说明真实 API 只需要替换 `InvoiceAPIClient` 实现。

## 10. 可扩展方向

- 增加扫码历史列表。
- 将 API 返回结果保存到本地。
- 增加登录鉴权。
- 增加发票图片 OCR。
- 增加网络错误重试。
- 增加单元测试和 UI 测试。

