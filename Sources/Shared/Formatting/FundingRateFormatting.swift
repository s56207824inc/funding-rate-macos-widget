import Foundation
import SwiftUI

enum FundingFormatters {
    static let percent: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let etfDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "M/d（EEE）"
        return formatter
    }()

    static let compactMillions: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    static let compactPriceUSD: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    static let compactBillions: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()
}

func formatFundingRate(_ value: Double?) -> String {
    guard let value else { return "--" }
    return FundingFormatters.percent.string(from: NSNumber(value: value)) ?? "--"
}

func formatNextFundingTime(_ date: Date?) -> String {
    guard let date else { return "N/A" }
    return FundingFormatters.time.string(from: date)
}

func formatUpdatedAt(_ date: Date?) -> String {
    guard let date else { return "尚未更新" }

    let seconds = Date().timeIntervalSince(date)
    if seconds < 15 {
        return "剛剛更新"
    }

    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}

func formatMillionsUSD(_ value: Double?) -> String {
    guard let value else { return "--" }
    let sign = value > 0 ? "+" : ""
    return "\(sign)\(FundingFormatters.compactMillions.string(from: NSNumber(value: value)) ?? "--")M"
}

func formatBillionsUSD(_ value: Double?) -> String {
    guard let value else { return "--" }
    let billions = value / 1_000_000_000
    return "$\(FundingFormatters.compactBillions.string(from: NSNumber(value: billions)) ?? "--")B"
}

func formatBillionsUSDChange(_ value: Double?) -> String {
    guard let value else { return "--" }
    let sign = value > 0 ? "+" : ""
    let billions = value / 1_000_000_000
    return "\(sign)$\(FundingFormatters.compactBillions.string(from: NSNumber(value: billions)) ?? "--")B"
}

func formatSignedPercent(_ value: Double?) -> String {
    guard let value else { return "--" }
    let sign = value > 0 ? "+" : ""
    return "\(sign)\(String(format: "%.2f", value))%"
}

func formatETFReportDate(_ date: Date?) -> String {
    guard let date else { return "未知交易日" }
    return FundingFormatters.etfDate.string(from: date)
}

func formatFearGreedValue(_ value: Int?) -> String {
    guard let value else { return "--" }
    return "\(value)"
}

func formatRSIValue(_ value: Double?) -> String {
    guard let value else { return "--" }
    return String(format: "%.1f", value)
}

func formatMVRVZScoreValue(_ value: Double?) -> String {
    guard let value else { return "--" }
    return String(format: "%.2f", value)
}

func formatCompactPriceUSD(_ value: Double?) -> String {
    guard let value else { return "--" }
    if value >= 1_000 {
        return "$\(FundingFormatters.compactPriceUSD.string(from: NSNumber(value: value / 1_000)) ?? "--")K"
    }
    return "$\(FundingFormatters.compactPriceUSD.string(from: NSNumber(value: value)) ?? "--")"
}

func fearGreedTint(for value: Int?) -> Color {
    guard let value else { return .gray }
    switch value {
    case 0..<25:
        return .blue
    case 25..<45:
        return .cyan
    case 45..<55:
        return .gray
    case 55..<75:
        return .orange
    default:
        return .red
    }
}

func rsiTint(for value: Double?) -> Color {
    guard let value else { return .gray }
    switch value {
    case ..<30:
        return .blue
    case 30..<45:
        return .cyan
    case 45..<55:
        return .gray
    case 55..<70:
        return .orange
    default:
        return .red
    }
}

struct RSIBand {
    let text: String
    let tint: Color
}

func rsiBand(for value: Double?) -> RSIBand {
    guard let value else {
        return RSIBand(text: "待確認", tint: .gray)
    }

    switch value {
    case ..<30:
        return RSIBand(text: "超賣", tint: .blue)
    case 30..<45:
        return RSIBand(text: "偏弱", tint: .cyan)
    case 45..<55:
        return RSIBand(text: "中性", tint: .gray)
    case 55..<70:
        return RSIBand(text: "偏熱", tint: .orange)
    default:
        return RSIBand(text: "超買", tint: .red)
    }
}

struct MVRVZScoreBand {
    let text: String
    let tint: Color
}

func mvrvZScoreTint(for value: Double?) -> Color {
    guard let value else { return .gray }
    switch value {
    case ..<0:
        return .blue
    case 0..<1:
        return .cyan
    case 1..<3:
        return .gray
    case 3..<5:
        return .orange
    default:
        return .red
    }
}

func mvrvZScoreBand(for value: Double?) -> MVRVZScoreBand {
    guard let value else {
        return MVRVZScoreBand(text: "待確認", tint: .gray)
    }

    switch value {
    case ..<0:
        return MVRVZScoreBand(text: "低估區", tint: .blue)
    case 0..<1:
        return MVRVZScoreBand(text: "偏低", tint: .cyan)
    case 1..<3:
        return MVRVZScoreBand(text: "中性", tint: .gray)
    case 3..<5:
        return MVRVZScoreBand(text: "偏熱", tint: .orange)
    default:
        return MVRVZScoreBand(text: "過熱", tint: .red)
    }
}

struct ETFNetFlowBand {
    let text: String
    let tint: Color
}

func etfNetFlowBand(for value: Double?) -> ETFNetFlowBand {
    guard let value else {
        return ETFNetFlowBand(text: "待確認", tint: .gray)
    }

    switch value {
    case 500...:
        return ETFNetFlowBand(text: "超大流入", tint: .red)
    case 250..<500:
        return ETFNetFlowBand(text: "強勁流入", tint: .orange)
    case 100..<250:
        return ETFNetFlowBand(text: "不錯", tint: .yellow)
    case 0..<100:
        return ETFNetFlowBand(text: "普通", tint: .blue)
    case -100..<0:
        return ETFNetFlowBand(text: "偏淡", tint: .gray)
    default:
        return ETFNetFlowBand(text: "明顯流出", tint: .green)
    }
}
