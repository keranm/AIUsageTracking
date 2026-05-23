import Foundation
import ServiceManagement

final class SettingsStore: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin() }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    // Token cap per 5-hour window (inference tokens only: input + output, not cache reads).
    // Default 500K derived from observation: 207K output tokens = 41% → cap ≈ 500K.
    // Users on different plans should calibrate this from Claude Code's /usage command.
    @Published var tokenCapPerWindow: Int {
        didSet { UserDefaults.standard.set(tokenCapPerWindow, forKey: "tokenCapPerWindow") }
    }

    init() {
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        let saved = UserDefaults.standard.integer(forKey: "tokenCapPerWindow")
        self.tokenCapPerWindow = saved > 0 ? saved : UsageCalculator.defaultTokenCap
        registerOnFirstLaunch()
    }

    private func registerOnFirstLaunch() {
        let key = "hasRegisteredLaunchAtLogin"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        try? SMAppService.mainApp.register()
        UserDefaults.standard.set(true, forKey: key)
        launchAtLogin = true
    }

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("SMAppService error: \(error)")
        }
    }
}
