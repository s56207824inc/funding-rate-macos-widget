# Funding Rate macOS Widget 規格

## 目標

做一個輕量的 macOS 右上角選單列 App，讓使用者可以隨時點擊 menu bar 圖示，快速查看 `BTC` 在以下交易所的永續合約 funding rate：

- Bybit
- Binance
- OKX
- Hyperliquid
- Bitget

這個 App 的核心目標是：

- 一眼可讀
- API 用量低
- 更新策略穩定
- 錯誤與過期狀態清楚


## 產品範圍

### 本期範圍

- macOS menu bar app
- 右上角常駐圖示
- 點擊後展開小面板 / popover
- 顯示 5 家交易所的 BTC funding rate
- 自動每 10 分鐘更新一次
- 支援手動刷新
- 顯示上次更新時間
- 顯示每家交易所的 loading / error / stale 狀態
- 將不同交易所回傳資料正規化後統一顯示

### 不在本期範圍

- BTC 以外的幣種
- 歷史走勢圖
- 推播通知
- 帳號登入
- 下單功能
- API key
- iOS / Web / Windows 版本


## 使用情境

作為使用者，我希望在 macOS 右上角點一下就能看到 BTC 在主要交易所的 funding rate，這樣我不用另外開瀏覽器或交易所頁面，也能快速比較 funding。


## 功能需求

### FR1. 選單列常駐

App 必須以 macOS menu bar app 形式運作，並在右上角顯示一個可點擊的圖示。

### FR2. 點擊後顯示面板

當使用者點擊選單列圖示時，App 必須顯示一個小面板，內容包含：

- 交易所名稱
- BTC funding rate
- 下一次 funding 時間（若有）
- 上次更新時間
- 手動刷新按鈕

### FR3. 自動更新

App 在執行中時，必須每 10 分鐘自動更新一次資料。

備註：

- 目標更新間隔為 `600 秒`
- 背景更新不應比需求更頻繁
- 若面板開啟時快取資料已超過 `60 秒`，可在顯示快取後補做一次背景刷新

### FR4. 手動刷新

使用者可以在面板中手動觸發資料更新。

### FR5. 單一交易所失敗不影響整體

若某一家交易所抓取失敗，其餘交易所仍應正常顯示。

每家交易所應能落在以下其中一種狀態：

- 最新資料
- 載入中
- 錯誤
- 過期但可顯示的快取資料

### FR6. 資料新鮮度標示

UI 應清楚標示資料的新鮮度，例如：

- `剛剛更新`
- `X 分鐘前更新`
- `資料過期`

### FR7. 僅支援 BTC

第一版只支援 BTC 永續 funding。

目標商品：

- Bybit: `BTCUSDT`
- Binance: `BTCUSDT`
- OKX: `BTC-USDT-SWAP`
- Hyperliquid: `BTC`
- Bitget: `BTCUSDT` + `USDT-FUTURES`


## 非功能需求

### NFR1. API 使用量低

App 的 request 量必須遠低於各交易所公開 API 的 rate limit。

預估請求量：

- 每次更新共 `5 requests`
- 每 10 分鐘更新一次
- 每小時 `30 requests`
- 每天 `720 requests`

這個量對於本案使用的公開 endpoint 來說都很安全。

### NFR2. 面板開啟要快

若有快取，面板應優先立即顯示快取資料，而不是等網路回來才開。

目標：

- 面板點開後 200ms 內可見既有資料

### NFR3. 容錯能力

單一交易所 API 故障、逾時或格式異常，不應拖垮整個 App。

### NFR4. 最小權限

App 僅使用公開 API，不需要 API key，也不需要任何交易權限。


## 背景更新行為

這一段是本案最重要的執行邏輯之一。

### 情境 A：App 仍在執行中

只要 App 還在執行，且仍常駐於 menu bar，就可以在背景依排程每 10 分鐘抓一次資料。

這是 v1 預設支援的模式。

### 情境 B：App 已完全退出

如果使用者把 App 完全關掉，App 就無法繼續在背景抓資料。

也就是說：

- v1 不做系統層 background task
- v1 不做 daemon / LaunchAgent / login item background fetch
- v1 不要求「App 沒開也持續更新」

這種情況下，下一次使用者重新打開 App 或點開 menu bar 面板時，App 應：

- 先顯示上次保存的快取資料
- 檢查距離上次成功抓取是否已超過 `60 秒`
- 如果超過，立即觸發一次刷新

所以你的理解是對的：

對 v1 來說，若 App 沒有在跑，就不會背景抓；下一次進來時再根據「上次抓取時間是否超過 60 秒」決定要不要立刻更新。

### v1 推薦產品決策

建議把 App 做成：

- 關閉主視窗後仍常駐 menu bar
- 只有使用者明確點 `Quit` 才完全退出

這樣使用體驗最像真正的選單列工具，也最符合你「隨時點右上角看 funding」的需求。


## 資料來源

只使用官方公開 API。

### Bybit

- Endpoint: `GET /v5/market/tickers`
- Params: `category=linear&symbol=BTCUSDT`
- 主要欄位：
  - `fundingRate`
  - `nextFundingTime`

### Binance

優先方案：

- Endpoint: `GET /fapi/v1/premiumIndex`
- Params: `symbol=BTCUSDT`
- 主要欄位：
  - `lastFundingRate`
  - `nextFundingTime`

備援方案：

- `GET /fapi/v1/fundingRate`
- 取最新一筆歷史 funding

### OKX

- Endpoint: `GET /api/v5/public/funding-rate`
- Params: `instId=BTC-USDT-SWAP`
- 主要欄位：
  - `fundingRate`
  - `nextFundingTime`

### Hyperliquid

- Endpoint: `POST https://api.hyperliquid.xyz/info`
- Body:
  - `{"type":"metaAndAssetCtxs"}`
- 主要欄位：
  - `funding`

後續可選增強：

- 若未來想顯示更多 venue comparison 資訊，可研究 `predictedFundings`
- 但 v1 不需要

### Bitget

- Endpoint: `GET /api/v2/mix/market/current-fund-rate`
- Params:
  - `symbol=BTCUSDT`
  - `productType=USDT-FUTURES`
- 主要欄位：
  - `fundingRate`
  - `nextUpdate`


## 正規化資料模型

建議統一成以下資料結構：

```ts
type ExchangeId = "bybit" | "binance" | "okx" | "hyperliquid" | "bitget";

type FundingRateSnapshot = {
  exchange: ExchangeId;
  symbol: "BTC";
  fundingRate: number | null;
  nextFundingTime: string | null;
  fetchedAt: string;
  sourceStatus: "ok" | "stale" | "error";
  errorMessage?: string;
};
```

備註：

- `fundingRate` 內部以小數保存，例如 `0.0001`
- UI 再轉成 `%` 顯示


## 顯示規則

### Funding Rate 顯示格式

v1 建議：

- 以百分比顯示
- 小數點後 4 位
- 範例：`0.0100%`

可選擇加上次要資訊：

- bps，例如 `1.00 bps`

### 每列顯示內容

每一家交易所顯示：

- 交易所名稱
- funding rate
- 下一次 funding 時間或 `N/A`
- 狀態標示，例如 stale / error

### 排序

v1 使用固定順序，避免列表跳動：

1. Bybit
2. Binance
3. OKX
4. Hyperliquid
5. Bitget


## 更新策略

### 預設策略

- 每 10 分鐘更新全部 5 家資料
- 5 家請求並行送出
- 每個 request 設 timeout，建議 `5 秒`

### 面板開啟時行為

當使用者點開面板時：

- 若快取資料距今小於 `60 秒`，直接顯示快取，不主動刷新
- 若快取資料距今超過 `60 秒`，先顯示快取，再觸發一次背景刷新

### 失敗重試策略

v1 不做激進重試。

建議：

- 單次請求失敗就先標記為 error
- 等下一次排程更新再重試
- 使用者手動 refresh 可立即重抓

可延後加入：

- 針對短暫網路失敗做一次輕量 backoff retry


## Rate Limit 評估

### 預估流量

每天請求量：

- `5 家 * 144 次刷新 = 720 requests/day`

平均每分鐘：

- `0.5 requests/minute`

### 結論

這個 BTC-only、10 分鐘刷新一次的 menu bar widget，實務上不會碰到這些公開 API 的 rate limit。

真正比較需要處理的是：

- 個別 API 偶發 timeout
- 某家回傳 schema 變動
- 使用者手動狂按 refresh

因此實作上只要加：

- timeout
- 快取
- loading state
- 基本防抖

就夠了。


## 快取策略

v1 使用：

- 記憶體快取
- 本地持久化最後一次成功資料

建議行為：

- 每家交易所保留最後一次成功快照
- 更新失敗時仍可顯示舊資料
- 若超過 `20 分鐘` 未成功更新，標記為 `stale`

本地持久化的目的：

- App 重新打開時，可以先顯示上次資料
- 不需要每次冷啟動都空白等待


## 錯誤狀態

每家交易所可能發生：

- 網路 timeout
- HTTP error
- JSON schema 不符
- parse 失敗

UI 規則：

- 若有舊快取：顯示舊值並標 `資料過期`
- 若沒有快取：顯示 `Unavailable`


## 技術方向

推薦 v1 採用：

- `SwiftUI`
- macOS 原生 menu bar app
- `MenuBarExtra`
- `URLSession`
- `async/await`

理由：

- 原生 menu bar 體驗最好
- 功能需求單純，依賴可壓低
- 很適合做小型常駐工具


## 建議架構

### 模組切分

- `App`
  - App entrypoint
  - menu bar integration
- `Domain`
  - funding rate 正規化資料模型
- `Services`
  - 每家交易所一個 fetcher
  - 聚合 service
- `ViewModel`
  - 更新排程
  - refresh orchestration
  - 狀態管理
- `UI`
  - menu bar panel
  - 每家交易所 row
  - footer 與操作區

### Exchange Service 介面概念

```ts
interface FundingRateProvider {
  var exchangeId: ExchangeId { get }
  func fetchBTCFundingRate() async throws -> FundingRateSnapshot
}
```

實作時會改成 Swift 風格，但概念上就是每家交易所提供同樣的抓取入口。


## UX 建議

### Menu Bar 顯示方式

可選方案：

- 只顯示 icon
- 顯示 icon + 簡短文字摘要

v1 建議：

- `只顯示 icon`

原因：

- menu bar 更乾淨
- 避免文字寬度一直變
- 降低第一版複雜度

### 面板底部

建議顯示：

- 上次更新時間
- Refresh 按鈕
- Quit 按鈕


## 紀錄與除錯

v1 使用簡單 log 即可。

記錄內容：

- refresh 開始
- refresh 完成
- 個別交易所抓取失敗
- parse 失敗

預設不要記整包 payload，除非進入 debug 模式。


## 安全性

- 僅使用公開 API
- 不保存任何秘密
- 不需要交易權限
- 不需要帳號登入


## 驗收標準

以下條件都成立，即可視為完成：

1. App 啟動後會出現在 macOS 右上角 menu bar。
2. 點擊圖示後可看到 5 家交易所的 BTC funding rate。
3. App 在執行中時會每 10 分鐘自動更新一次。
4. 使用者可手動刷新。
5. 單一交易所失敗不會影響其他交易所顯示。
6. UI 會顯示上次更新時間與 stale / error 狀態。
7. 全部使用公開 API，不需要 API key。
8. 正常使用下不會碰到 rate limit。
9. 若 App 完全退出，重新打開時會先顯示上次快取，並在資料超過 60 秒時自動補抓。


## 需要你確認的決策

在開工前，只剩這幾個值得確認：

1. Menu bar 樣式
   - 只顯示 icon
   - icon + 文字摘要

2. 點開面板時的刷新邏輯
   - 只有手動 refresh
   - 若資料超過 60 秒，自動背景 refresh

3. Stale threshold
   - 建議 20 分鐘


## 預設實作決策

如果沒有額外修改，v1 就照以下方式開工：

- 原生 SwiftUI macOS menu bar app
- menu bar 只顯示 icon
- 只支援 BTC
- App 執行中每 10 分鐘更新一次
- 若 App 完全退出，不做背景更新
- 重新打開時先讀上次快取
- 若資料超過 60 秒，立刻背景刷新
- stale threshold 設為 20 分鐘
- 5 家交易所並行抓取官方公開 API

