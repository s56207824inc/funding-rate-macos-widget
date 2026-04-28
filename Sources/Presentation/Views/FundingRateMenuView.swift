import AppKit
import SwiftUI

struct FundingRateMenuView: View {
    @ObservedObject var viewModel: FundingRateMenuViewModel

    private let panelWidth: CGFloat = 388
    private let panelMaxHeight: CGFloat = 556
    private let surfaceTint = Color(red: 0.14, green: 0.15, blue: 0.17)
    private let outlineTint = Color.white.opacity(0.08)

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 14) {
                header
                overviewCard
                onChainCard
                fundingCard
                footer
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: panelWidth)
        .frame(maxHeight: panelMaxHeight, alignment: .top)
        .background(panelBackground)
        .task {
            viewModel.refreshIfNeededForPanelOpen()
        }
    }

    private var panelBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.11, blue: 0.12),
                    Color(red: 0.16, green: 0.16, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.07),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 240
                    )
                )
                .padding(-40)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BTC Pulse")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()

            HStack(spacing: 8) {
                if viewModel.isRefreshing {
                    StatusBadge(text: "更新中", tint: .blue)
                } else {
                    StatusBadge(text: headerStatusText, tint: headerStatusTint)
                }
            }
        }
    }

    private var overviewCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Market Snapshot")

                HStack(alignment: .top, spacing: 10) {
                    compactMetric(
                        title: "ETF",
                        value: formatMillionsUSD(viewModel.bitcoinETFNetFlow?.totalNetFlowMillionsUSD),
                        tone: etfFlowColor,
                        badgeText: etfFlowBand.text,
                        badgeTint: etfFlowBand.tint,
                        detail: etfSummaryText
                    )

                    compactMetric(
                        title: "Fear & Greed",
                        value: formatFearGreedValue(viewModel.cryptoFearGreed?.value),
                        tone: fearGreedColor,
                        badgeText: fearGreedShortLabel,
                        badgeTint: fearGreedColor,
                        detail: fearGreedSummaryText
                    )

                    compactMetric(
                        title: "RSI",
                        value: formatRSIValue(viewModel.bitcoinRSI?.value),
                        tone: rsiColor,
                        badgeText: rsiStateBand.text,
                        badgeTint: rsiStateBand.tint,
                        detail: rsiSummaryText
                    )
                }
            }
        }
    }

    private var onChainCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        sectionLabel("On-chain Valuation")
                        Text(mvrvSummaryText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                    }

                    Spacer()

                    StatusBadge(text: mvrvZScoreStateBand.text, tint: mvrvZScoreStateBand.tint)
                }

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(formatMVRVZScoreValue(viewModel.bitcoinMVRVZScore?.value))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(mvrvZScoreColor)

                    Text("Z")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.54))
                        .padding(.bottom, 4)

                    Spacer()
                }

                HStack(spacing: 10) {
                    infoStrip(label: "Realized", value: formatCompactPriceUSD(viewModel.bitcoinMVRVZScore?.realizedPriceUSD))
                    infoStrip(label: "STH", value: formatCompactPriceUSD(viewModel.bitcoinMVRVZScore?.shortTermHolderRealizedPriceUSD))
                }
            }
        }
    }

    private var fundingCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    sectionLabel("Funding")
                    Spacer()
                    Text("10m cadence")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.48))
                }

                VStack(spacing: 0) {
                    ForEach(Array(ExchangeID.allCases.enumerated()), id: \.element) { index, exchange in
                        let snapshot = viewModel.snapshot(for: exchange)
                            ?? FundingRateSnapshot.failed(for: exchange, previous: nil, message: "尚未取得資料")

                        FundingRateRowView(snapshot: snapshot)

                        if index < ExchangeID.allCases.count - 1 {
                            Divider()
                                .overlay(Color.white.opacity(0.06))
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(viewModel.footerText)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.52))

            Spacer()

            Button("Refresh") {
                viewModel.refresh(force: true)
            }
            .buttonStyle(FooterButtonStyle())
            .keyboardShortcut("r", modifiers: [.command])

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(FooterButtonStyle())
        }
    }

    private func compactMetric(
        title: String,
        value: String,
        tone: Color,
        badgeText: String,
        badgeTint: Color,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.52))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tone)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            StatusBadge(text: badgeText, tint: badgeTint)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.60))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func infoStrip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.48))
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.16))
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(.white.opacity(0.48))
            .textCase(.uppercase)
    }

    private var headerSubtitle: String {
        if viewModel.isRefreshing {
            return "正在同步最新市場資料"
        }

        return viewModel.footerText
    }

    private var headerStatusText: String {
        let statuses = [
            viewModel.bitcoinETFNetFlow?.sourceStatus,
            viewModel.cryptoFearGreed?.sourceStatus,
            viewModel.bitcoinRSI?.sourceStatus,
            viewModel.bitcoinMVRVZScore?.sourceStatus
        ]

        if statuses.contains(.error) { return "部分失敗" }
        if statuses.contains(.stale) { return "含快取" }
        return "已更新"
    }

    private var headerStatusTint: Color {
        let statuses = [
            viewModel.bitcoinETFNetFlow?.sourceStatus,
            viewModel.cryptoFearGreed?.sourceStatus,
            viewModel.bitcoinRSI?.sourceStatus,
            viewModel.bitcoinMVRVZScore?.sourceStatus
        ]

        if statuses.contains(.error) { return .gray }
        if statuses.contains(.stale) { return .orange }
        return .green
    }

    private var etfSummaryText: String {
        guard let snapshot = viewModel.bitcoinETFNetFlow else {
            return "等待資料"
        }

        switch snapshot.sourceStatus {
        case .ok:
            return formatETFReportDate(snapshot.reportDate)
        case .stale:
            return "\(formatETFReportDate(snapshot.reportDate)) 休市沿用"
        case .error:
            return "資料暫時不可用"
        case .loading:
            return "更新中"
        }
    }

    private var fearGreedSummaryText: String {
        guard let snapshot = viewModel.cryptoFearGreed else {
            return "等待資料"
        }

        switch snapshot.sourceStatus {
        case .ok:
            return formatETFReportDate(snapshot.reportDate)
        case .stale:
            return "\(formatETFReportDate(snapshot.reportDate)) · 快取"
        case .error:
            return "資料暫時不可用"
        case .loading:
            return "更新中"
        }
    }

    private var fearGreedShortLabel: String {
        switch viewModel.cryptoFearGreed?.sourceStatus {
        case .ok:
            return viewModel.cryptoFearGreed?.classification ?? "未知"
        case .stale:
            return viewModel.cryptoFearGreed?.classification ?? "快取"
        case .error:
            return "失敗"
        case .loading:
            return "更新中"
        case .none:
            return "等待"
        }
    }

    private var rsiSummaryText: String {
        guard let snapshot = viewModel.bitcoinRSI else {
            return "等待資料"
        }

        let descriptor = "\(snapshot.intervalLabel) RSI(\(snapshot.period))"
        switch snapshot.sourceStatus {
        case .ok:
            return descriptor
        case .stale:
            return "\(descriptor) · 快取"
        case .error:
            return "資料暫時不可用"
        case .loading:
            return "更新中"
        }
    }

    private var mvrvSummaryText: String {
        guard let snapshot = viewModel.bitcoinMVRVZScore else {
            return "等待資料"
        }

        switch snapshot.sourceStatus {
        case .ok:
            return formatETFReportDate(snapshot.reportDate)
        case .stale:
            return "顯示上次成功資料"
        case .error:
            return "資料暫時不可用"
        case .loading:
            return "更新中"
        }
    }

    private var etfFlowColor: Color {
        guard let value = viewModel.bitcoinETFNetFlow?.totalNetFlowMillionsUSD else { return .white }
        if value > 0 { return Color(red: 0.98, green: 0.42, blue: 0.36) }
        if value < 0 { return Color(red: 0.39, green: 0.82, blue: 0.54) }
        return .white
    }

    private var etfFlowBand: ETFNetFlowBand {
        etfNetFlowBand(for: viewModel.bitcoinETFNetFlow?.totalNetFlowMillionsUSD)
    }

    private var fearGreedColor: Color {
        fearGreedTint(for: viewModel.cryptoFearGreed?.value)
    }

    private var rsiColor: Color {
        rsiTint(for: viewModel.bitcoinRSI?.value)
    }

    private var rsiStateBand: RSIBand {
        rsiBand(for: viewModel.bitcoinRSI?.value)
    }

    private var mvrvZScoreColor: Color {
        mvrvZScoreTint(for: viewModel.bitcoinMVRVZScore?.value)
    }

    private var mvrvZScoreStateBand: MVRVZScoreBand {
        mvrvZScoreBand(for: viewModel.bitcoinMVRVZScore?.value)
    }
}

private struct FundingRateRowView: View {
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

private struct DashboardCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct FooterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.16 : 0.10))
            )
            .foregroundStyle(.white.opacity(0.88))
    }
}

private struct StatusBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.16))
            )
            .foregroundStyle(tint)
    }
}
