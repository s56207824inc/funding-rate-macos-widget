import SwiftUI

struct BuySignalThermometer: View {
    let fillRatio: Double
    let fillColor: Color
    let effectsOpacity: Double

    var body: some View {
        GeometryReader { proxy in
            let clampedRatio = max(0, min(1, fillRatio))
            let tubeHeight: CGFloat = 26
            let tubeWidth = proxy.size.width
            let fillWidth = max(12, tubeWidth * clampedRatio)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.075),
                                Color.white.opacity(0.035)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: tubeWidth, height: tubeHeight)
                    .overlay(alignment: .leading) {
                        Capsule(style: .continuous)
                            .strokeBorder(Color.white.opacity(0.13), lineWidth: 1)
                            .frame(width: tubeWidth, height: tubeHeight)
                    }

                AnimatedLiquidFill(
                    fillColor: fillColor,
                    width: fillWidth,
                    height: tubeHeight,
                    effectsOpacity: effectsOpacity
                )
                .shadow(
                    color: fillColor.opacity(0.06 + effectsOpacity * 0.08),
                    radius: 3 + effectsOpacity * 3
                )

                HStack(spacing: 0) {
                    ForEach(1..<10, id: \.self) { index in
                        Rectangle()
                            .fill(Color.white.opacity(index == 5 ? 0.18 : 0.09))
                            .frame(width: 1, height: index == 5 ? 14 : 8)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: tubeWidth - 26, height: tubeHeight)
                .padding(.horizontal, 13)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 34)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: fillRatio)
    }
}

private struct AnimatedLiquidFill: View {
    let fillColor: Color
    let width: CGFloat
    let height: CGFloat
    let effectsOpacity: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            liquidContent(phase: timeline.date.timeIntervalSinceReferenceDate)
        }
        .frame(width: width, height: height)
        .clipShape(Capsule(style: .continuous))
    }

    private func liquidContent(phase: TimeInterval) -> some View {
        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(liquidGradient)

            LiquidWaveLine(
                phase: phase * 2.2,
                amplitude: height * 0.13,
                verticalOffset: height * 0.38,
                wavelength: 76
            )
            .stroke(Color.white.opacity(0.16), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            .opacity(effectsOpacity)

            LiquidWaveLine(
                phase: -phase * 1.65,
                amplitude: height * 0.10,
                verticalOffset: height * 0.60,
                wavelength: 58
            )
            .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))
            .opacity(effectsOpacity)

            LiquidBubbles(
                phase: phase,
                fillColor: fillColor,
                width: width,
                height: height
            )
            .opacity(effectsOpacity)

            LiquidFish(
                phase: phase,
                width: width,
                height: height
            )
            .opacity(0.22 + effectsOpacity * 0.30)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.00),
                    Color.white.opacity(0.14),
                    Color.white.opacity(0.00)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: max(34, width * 0.42), height: height)
            .offset(x: waveHighlightOffset(phase: phase))
            .opacity(effectsOpacity)
        }
    }

    private var liquidGradient: LinearGradient {
        LinearGradient(
            colors: [
                fillColor.opacity(0.68),
                fillColor.opacity(0.94),
                fillColor
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func waveHighlightOffset(phase: TimeInterval) -> CGFloat {
        guard width > 1 else { return 0 }
        let travel = width + max(34, width * 0.42)
        let progress = CGFloat(phase.truncatingRemainder(dividingBy: 2.8) / 2.8)
        return -max(34, width * 0.42) + travel * progress
    }
}

private struct LiquidFish: View {
    let phase: TimeInterval
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        let size = max(10, min(16, height * 0.56))
        let cycleDuration = 7.8
        let angle = phase / cycleDuration * 2 * .pi - (.pi / 2)
        let progress = CGFloat((sin(angle) + 1) * 0.5)
        let isMovingRight = cos(angle) >= 0
        let sidePadding = max(10, size)
        let travelWidth = max(1, width - sidePadding * 2)
        let x = sidePadding + travelWidth * progress
        let y = height * 0.52 + sin(phase * 1.25) * min(2.2, height * 0.08)

        Image(systemName: "fish.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color(red: 1.00, green: 0.84, blue: 0.26).opacity(0.82))
            .frame(width: size * 1.35, height: size)
            .scaleEffect(x: isMovingRight ? 1 : -1, y: 1)
            .rotationEffect(.degrees(sin(phase * 1.25) * 3))
            .position(x: x, y: y)
            .shadow(color: Color.black.opacity(0.10), radius: 1, x: 0, y: 0.5)
    }
}

private struct LiquidBubbles: View {
    let phase: TimeInterval
    let fillColor: Color
    let width: CGFloat
    let height: CGFloat

    private let specs = [
        LiquidBubbleSpec(id: 0, delay: 0.00, duration: 1.80, size: 4.2, startX: 0.28, driftX: 5.0, riseY: 15),
        LiquidBubbleSpec(id: 1, delay: 0.26, duration: 2.10, size: 3.1, startX: 0.48, driftX: 6.5, riseY: 13),
        LiquidBubbleSpec(id: 2, delay: 0.58, duration: 1.65, size: 2.6, startX: 0.68, driftX: 4.4, riseY: 11),
        LiquidBubbleSpec(id: 3, delay: 0.82, duration: 2.25, size: 2.2, startX: 0.82, driftX: 5.8, riseY: 14)
    ]

    var body: some View {
        ZStack {
            ForEach(specs) { spec in
                let progress = bubbleProgress(for: spec)
                let easedProgress = easeOut(progress)
                let x = width * spec.startX + wobble(for: spec)
                let y = height - 5 - easedProgress * spec.riseY

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.44 * (1 - progress)),
                                fillColor.opacity(0.24 * (1 - progress))
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: spec.size
                        )
                    )
                    .frame(width: spec.size, height: spec.size)
                    .position(
                        x: min(max(6, x), width - 6),
                        y: min(max(5, y), height - 5)
                    )
                    .opacity(0.78 - progress * 0.62)
            }
        }
    }

    private func bubbleProgress(for spec: LiquidBubbleSpec) -> CGFloat {
        let cyclePosition = (phase / spec.duration + spec.delay).truncatingRemainder(dividingBy: 1)
        return CGFloat(cyclePosition)
    }

    private func easeOut(_ value: CGFloat) -> CGFloat {
        1 - pow(1 - value, 2)
    }

    private func wobble(for spec: LiquidBubbleSpec) -> CGFloat {
        sin(phase * 4.1 + Double(spec.id)) * spec.driftX
    }
}

private struct LiquidBubbleSpec: Identifiable {
    let id: Int
    let delay: TimeInterval
    let duration: TimeInterval
    let size: CGFloat
    let startX: CGFloat
    let driftX: CGFloat
    let riseY: CGFloat
}

private struct LiquidWaveLine: Shape {
    let phase: TimeInterval
    let amplitude: CGFloat
    let verticalOffset: CGFloat
    let wavelength: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 4
        var x = rect.minX

        while x <= rect.maxX {
            let relativeX = x - rect.minX
            let angle = (relativeX / wavelength * 2 * .pi) + phase
            let y = rect.minY + verticalOffset + sin(angle) * amplitude

            if x == rect.minX {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }

            x += step
        }

        return path
    }
}
