# InvoiceQRScanner

一个 SwiftUI iOS 示例应用：扫描发票二维码，将二维码内容作为参数提交给 API，拿到返回值后以弹窗展示。

当前版本使用 mock API，便于先完成作业演示和 UI/流程验证。后续只需要替换 `InvoiceAPIClient` 实现即可接入真实后端。

## 功能

- SwiftUI 原生界面
- 调用摄像头扫描发票二维码
- 使用 mock API 模拟“二维码内容作为参数发送给接口”
- 弹窗展示接口返回值
- 支持 Simulator mock 扫码数据
- 使用开源组件简化开发：
  - [CodeScanner](https://github.com/twostraws/CodeScanner)：SwiftUI 二维码/条码扫描组件
  - [XcodeGen](https://github.com/yonaskolb/XcodeGen)：根据 `project.yml` 生成 Xcode 工程

## 快速运行

1. 安装 Xcode 15 或更新版本。
2. 安装 XcodeGen：

   ```bash
   brew install xcodegen
   ```

3. 在项目根目录生成工程：

   ```bash
   xcodegen generate
   ```

4. 打开工程：

   ```bash
   open InvoiceQRScanner.xcodeproj
   ```

5. 选择 iPhone Simulator 或真机，点击 Run。

> 真机扫描需要摄像头权限。Simulator 无法使用真实摄像头，本项目已配置 mock 扫码内容。

## 项目结构

```text
InvoiceQRScanner/
  App/
    InvoiceQRScannerApp.swift
  Features/
    Scanner/
      ScannerSheet.swift
    Home/
      ContentView.swift
  Models/
    InvoiceAPIResponse.swift
  Services/
    InvoiceAPIClient.swift
  ViewModels/
    InvoiceScannerViewModel.swift
  Resources/
    Info.plist
Docs/
  DevelopmentGuide.md
project.yml
```

## 后续接入真实 API

修改 [InvoiceAPIClient.swift](InvoiceQRScanner/Services/InvoiceAPIClient.swift)，将 `MockInvoiceAPIClient` 替换为 `URLSessionInvoiceAPIClient`，并在 `InvoiceScannerViewModel` 初始化时注入真实实现。

详细步骤见 [开发文档](Docs/DevelopmentGuide.md)。

