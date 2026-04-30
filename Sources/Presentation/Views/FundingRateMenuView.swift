import AppKit
import SwiftUI

struct FundingRateMenuView: View {
    @ObservedObject var viewModel: FundingRateMenuViewModel
    @State private var showsDetails = false
    @State private var selectedStablecoinRange = StablecoinRange.sevenDays
    @State private var panelOpacity = 0.0
    @State private var liquidEffectsOpacity = 0.0

    private let panelWidth: CGFloat = 388
    private let surfaceTint = Color(red: 0.14, green: 0.15, blue: 0.17)
    private let outlineTint = Color.white.opacity(0.08)

    var body: some View {
        Group {
            if showsDetails {
                ScrollView(.vertical, showsIndicators: true) {
                    menuContent
                }
                .frame(height: expandedPanelHeight, alignment: .top)
            } else {
                menuContent
            }
        }
        .frame(width: panelWidth)
        .background(panelBackground)
        .opacity(panelOpacity)
        .scaleEffect(panelOpacity < 1 ? 0.985 : 1, anchor: .top)
        .onAppear {
            panelOpacity = 0
            liquidEffectsOpacity = 0

            withAnimation(.easeOut(duration: 0.30)) {
                panelOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                withAnimation(.easeOut(duration: 0.42)) {
                    liquidEffectsOpacity = 1
                }
            }
        }
        .onDisappear {
            panelOpacity = 0
            liquidEffectsOpacity = 0
        }
        .task {
            viewModel.refreshIfNeededForPanelOpen()
        }
    }

    private var expandedPanelHeight: CGFloat {
        let visibleScreenHeight = NSScreen.main?.visibleFrame.height ?? 820
        return min(760, visibleScreenHeight - 96)
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            accumulationThermometerCard

            if showsDetails {
                scoreDetailsCard
                overviewCard
                stablecoinSupplyCard
                onChainCard
                fundingCard
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var closeButton: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(CloseButtonStyle())
    }

    private var accumulationThermometerCard: some View {
        let score = viewModel.accumulationScore

        return DashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(score.statusText)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(score.subtitleText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    closeButton
                }

                BuySignalThermometer(
                    fillRatio: score.fillRatio,
                    fillColor: temperatureColor(for: score),
                    effectsOpacity: liquidEffectsOpacity
                )

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        showsDetails.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showsDetails ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                        Text(showsDetails ? "收起細節" : "Details")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.07))
                    )
                    .foregroundStyle(.white.opacity(0.88))
                }
                .buttonStyle(.plain)

                refreshControlRow
            }
        }
    }

    private var scoreDetailsCard: some View {
        let score = viewModel.accumulationScore

        return DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Why")

                VStack(spacing: 0) {
                    ForEach(Array(score.items.enumerated()), id: \.element.id) { index, item in
                        scoreDetailRow(item)

                        if index < score.items.count - 1 {
                            Divider()
                                .overlay(Color.white.opacity(0.06))
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }

    private func scoreDetailRow(_ item: AccumulationScoreItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: item.isTriggered ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(item.isTriggered ? Color.green : Color.white.opacity(0.28))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Text(item.detail)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(item.valueText)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.86))

                Text("\(formatWeight(item.weight)) pts")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.42))
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

    private var stablecoinSupplyCard: some View {
        let snapshot = viewModel.stablecoinSupply

        return DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        sectionLabel("Stablecoin Liquidity")
                        Text(stablecoinSummaryText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                    }

                    Spacer()

                    stablecoinRangePicker
                }

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(formatBillionsUSD(snapshot?.totalMarketCapUSD))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    Spacer()
                }

                HStack(spacing: 10) {
                    infoStrip(
                        label: "\(selectedStablecoinRange.title) Change",
                        value: formatBillionsUSDChange(stablecoinSelectedChangeUSD)
                    )
                    infoStrip(
                        label: "\(selectedStablecoinRange.title) %",
                        value: formatSignedPercent(stablecoinSelectedChangePercent)
                    )
                }
            }
        }
    }

    private var stablecoinRangePicker: some View {
        HStack(spacing: 4) {
            ForEach(StablecoinRange.allCases) { range in
                Button {
                    selectedStablecoinRange = range
                } label: {
                    Text(range.title)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selectedStablecoinRange == range ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
                        )
                        .foregroundStyle(selectedStablecoinRange == range ? .white : .white.opacity(0.58))
                }
                .buttonStyle(.plain)
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

    private var refreshControlRow: some View {
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
            return snapshot.reportDate.map(formatETFReportDate) ?? snapshot.sourceName
        case .stale:
            return "顯示上次成功資料"
        case .error:
            return "資料暫時不可用"
        case .loading:
            return "更新中"
        }
    }

    private var stablecoinSummaryText: String {
        guard let snapshot = viewModel.stablecoinSupply else {
            return "等待資料"
        }

        switch snapshot.sourceStatus {
        case .ok:
            return snapshot.reportDate.map(formatETFReportDate) ?? snapshot.sourceName
        case .stale:
            return "顯示上次成功資料"
        case .error:
            return "資料暫時不可用"
        case .loading:
            return "更新中"
        }
    }

    private var stablecoinSelectedChangeUSD: Double? {
        switch selectedStablecoinRange {
        case .sevenDays:
            return viewModel.stablecoinSupply?.change7DUSD
        case .thirtyDays:
            return viewModel.stablecoinSupply?.change30DUSD
        }
    }

    private var stablecoinSelectedChangePercent: Double? {
        switch selectedStablecoinRange {
        case .sevenDays:
            return viewModel.stablecoinSupply?.change7DPercent
        case .thirtyDays:
            return viewModel.stablecoinSupply?.change30DPercent
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

    private func temperatureColor(for score: AccumulationScore) -> Color {
        let ratio = score.fillRatio
        switch ratio {
        case 1...:
            return Color(red: 1.00, green: 0.79, blue: 0.22)
        case ..<0.25:
            return Color(red: 0.45, green: 0.55, blue: 0.68)
        case 0.25..<0.45:
            return Color(red: 0.24, green: 0.68, blue: 0.76)
        case 0.45..<0.65:
            return Color(red: 0.95, green: 0.74, blue: 0.26)
        case 0.65..<0.85:
            return Color(red: 1.00, green: 0.50, blue: 0.23)
        default:
            return Color(red: 1.00, green: 0.25, blue: 0.18)
        }
    }

    private func formatWeight(_ value: Double) -> String {
        value == floor(value) ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }
}

private enum StablecoinRange: String, CaseIterable, Identifiable {
    case sevenDays
    case thirtyDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sevenDays:
            return "7D"
        case .thirtyDays:
            return "30D"
        }
    }
}
