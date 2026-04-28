import SwiftUI

@main
struct FundingRateWidgetApp: App {
    @StateObject private var viewModel: FundingRateMenuViewModel = FundingRateWidgetDependencies.makeViewModel()

    var body: some Scene {
        MenuBarExtra {
            FundingRateMenuView(viewModel: viewModel)
        } label: {
            Image(systemName: "chart.line.uptrend.xyaxis")
        }
        .menuBarExtraStyle(.window)
    }
}
