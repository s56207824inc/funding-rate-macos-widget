// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FundingRateWidget",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "FundingRateWidget",
            targets: ["FundingRateWidget"]
        )
    ],
    targets: [
        .executableTarget(
            name: "FundingRateWidget",
            path: "Sources"
        )
    ]
)
