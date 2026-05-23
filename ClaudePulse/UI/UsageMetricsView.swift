import SwiftUI

struct UsageMetricsView: View {
    let usage: WindowUsage

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    // Show percentage when a cap is configured (percentUsed > 0 or tokens exist)
                    if usage.percentUsed > 0 || usage.inferenceTokens == 0 {
                        Text("\(usage.percentInt)%")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(usage.state.color)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.3), value: usage.percentInt)
                    } else {
                        Text(usage.tokenString)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(usage.state.color)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.3), value: usage.inferenceTokens)
                    }

                    Text(subtitleText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(usage.resetCountdownString)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: usage.secondsUntilReset)

                    Text("until reset")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            UsageProgressBar(percent: usage.percentUsed, state: usage.state)

            GuidanceTextView(state: usage.state)
        }
    }

    private var subtitleText: String {
        var parts: [String] = []
        if usage.inferenceTokens > 0 {
            parts.append("\(usage.tokenString) tokens")
        }
        parts.append(String(format: "$%.2f", usage.costUSD))
        parts.append("5-hour window")
        return parts.joined(separator: " · ")
    }
}
