import Foundation

struct WindowUsage {
    // Inference tokens = input + output (what Anthropic rate-limits on).
    // Cache tokens excluded — empirically not counted toward the 5h window cap.
    let inferenceTokens: Int
    let cacheTokens: Int           // cache_read + cache_write (informational only)
    let costUSD: Double
    let percentUsed: Double        // inferenceTokens / tokenCap, or 0 if tokenCap == 0
    let windowStart: Date
    let windowEnd: Date
    let secondsUntilReset: TimeInterval
    let isActive: Bool

    var state: UsageState {
        UsageState.from(percent: percentUsed, isActive: isActive)
    }

    var resetCountdownString: String {
        let total = Int(secondsUntilReset)
        let hours   = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0  { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "<1m"
    }

    var percentInt: Int { Int(percentUsed * 100) }

    var tokenString: String {
        let k = inferenceTokens
        if k >= 1_000_000 { return String(format: "%.1fM", Double(k) / 1_000_000) }
        if k >= 1_000     { return "\(k / 1_000)K" }
        return "\(k)"
    }

    static var empty: WindowUsage {
        WindowUsage(inferenceTokens: 0, cacheTokens: 0, costUSD: 0, percentUsed: 0,
                    windowStart: Date(), windowEnd: Date(),
                    secondsUntilReset: 5 * 3600, isActive: false)
    }
}

final class UsageCalculator {
    static let windowDuration: TimeInterval = 5 * 3600  // 5 hours
    // Empirically derived: 207K output tokens = 41% of cap → cap ≈ 500K.
    // Cache reads (30M+ per session) are NOT counted — Anthropic excludes them from rate limits.
    static let defaultTokenCap: Int         = 500_000
    static let activityCutoff: TimeInterval = 300       // "active" if request in last 5 min

    func calculate(entries: [JSONLEntry], tokenCap: Int, now: Date = Date()) -> WindowUsage {
        let windowStart  = now.addingTimeInterval(-Self.windowDuration)
        let recentCutoff = now.addingTimeInterval(-Self.activityCutoff)

        var inferenceTokens = 0
        var cacheTokens     = 0
        var totalCost       = 0.0
        var oldestInWindow: Date?
        var isActive        = false

        for entry in entries {
            guard let ts = entry.timestamp,
                  entry.message?.role == "assistant",
                  let usage = entry.message?.usage,
                  ts >= windowStart && ts <= now else { continue }

            inferenceTokens += (usage.inputTokens ?? 0) + (usage.outputTokens ?? 0)
            cacheTokens     += (usage.cacheReadInputTokens ?? 0) + (usage.cacheCreationInputTokens ?? 0)
            totalCost       += usage.cost(for: entry.message?.model)

            if oldestInWindow == nil || ts < oldestInWindow! { oldestInWindow = ts }
            if !isActive && ts >= recentCutoff { isActive = true }
        }

        let percent = tokenCap > 0 ? min(Double(inferenceTokens) / Double(tokenCap), 1.0) : 0

        let resetDate = oldestInWindow
            .map { $0.addingTimeInterval(Self.windowDuration) }
            ?? now.addingTimeInterval(Self.windowDuration)

        return WindowUsage(
            inferenceTokens: inferenceTokens,
            cacheTokens: cacheTokens,
            costUSD: totalCost,
            percentUsed: percent,
            windowStart: windowStart,
            windowEnd: now,
            secondsUntilReset: max(0, resetDate.timeIntervalSince(now)),
            isActive: isActive
        )
    }
}
