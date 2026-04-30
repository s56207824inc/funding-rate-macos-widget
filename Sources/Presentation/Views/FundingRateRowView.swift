import SwiftUI

struct FundingRateRowView: View {
    let snapshot: FundingRateSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(rateColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.exchange.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text(detailText)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatFundingRate(snapshot.fundingRate))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(rateColor)

                Text(statusLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(statusTint)
            }
        }
    }

    private var rateColor: Color {
        guard let value = snapshot.fundingRate else { return .white.opacity(0.7) }
        if value > 0 { return Color(red: 0.98, green: 0.42, blue: 0.36) }
        if value < 0 { return Color(red: 0.39, green: 0.82, blue: 0.54) }
        return .white.opacity(0.9)
    }

    private var statusTint: Color {
        switch snapshot.sourceStatus {
        case .ok:
            return .green
        case .stale:
            return .orange
        case .error:
            return .gray
        case .loading:
            return .blue
        }
    }

    private var statusLabel: String {
        switch snapshot.sourceStatus {
        case .ok:
            return "最新"
        case .stale:
            return "快取"
        case .error:
            return "失敗"
        case .loading:
            return "更新中"
        }
    }

    private var detailText: String {
        switch snapshot.sourceStatus {
        case .ok, .stale:
            return "Next \(formatNextFundingTime(snapshot.nextFundingTime))"
        case .error:
            return snapshot.errorMessage ?? "暫時無法取得資料"
        case .loading:
            return "正在抓取最新資料"
        }
    }
}
