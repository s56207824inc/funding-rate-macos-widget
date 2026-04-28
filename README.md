# funding-rate-macos-widget

macOS 右上角 menu bar widget，用來快速查看 BTC 在多家交易所的 funding rate。

## 開發需求

- macOS 14+
- Xcode 16+

## 開啟方式

直接用 Xcode 開啟：

- [FundingRateWidget.xcodeproj](/Users/wangyuquan/funding-rate-macos-widget/FundingRateWidget.xcodeproj)

然後選擇 `FundingRateWidget` scheme，直接執行即可。

## 命令列驗證

也可以在終端機測試編譯：

```bash
xcodebuild -project FundingRateWidget.xcodeproj -scheme FundingRateWidget -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

專案裡仍保留 `Package.swift`，主要是方便快速做 SwiftPM 級別的編譯驗證；日常開發請以 `FundingRateWidget.xcodeproj` 為主。

## 安裝成可直接使用的 App

如果你想脫離 Xcode 直接使用：

```bash
chmod +x scripts/install_app.sh
./scripts/install_app.sh
```

安裝完成後，App 會被複製到：

```bash
~/Applications/FundingRateWidget.app
```

之後直接打開這個 `.app` 即可，不需要讓 Xcode 持續開著。

`install_app.sh` 會先做一次乾淨的 `Release` 重建再安裝，避免把舊的 release 產物複製到 `~/Applications`。

## 規格

產品規格請見 [spec.md](spec.md)
