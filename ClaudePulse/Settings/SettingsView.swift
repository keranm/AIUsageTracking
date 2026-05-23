import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("Usage Window") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Token cap (5-hour window)")
                        Spacer()
                        Text(formattedCap)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: Binding(
                            get: { Double(settings.tokenCapPerWindow) },
                            set: { settings.tokenCapPerWindow = Int($0) }
                        ),
                        in: 100_000...2_000_000,
                        step: 50_000
                    )
                    Text("Tracks inference tokens (input + output) against your 5-hour cap. Check Claude Code's /usage command to find your exact cap and calibrate this slider. Default 500K is based on observed Max plan data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Notifications") {
                Toggle("Enable usage warnings", isOn: $settings.notificationsEnabled)
            }

            Section("System") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 340)
        .navigationTitle("Claude Pulse Settings")
    }

    private var formattedCap: String {
        let k = settings.tokenCapPerWindow
        if k >= 1_000_000 { return String(format: "%.1fM tokens", Double(k) / 1_000_000) }
        return "\(k / 1_000)K tokens"
    }
}
