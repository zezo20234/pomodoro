import Foundation
import UIKit
import SwiftUI
import Capacitor
import FamilyControls
import ManagedSettings

private struct PickerScreen: View {
    @State var selection: FamilyActivitySelection
    let onDone: (FamilyActivitySelection) -> Void
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Choose apps & sites")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { onDone(selection) }
                    }
                }
        }
    }
}

@objc(ScreenTimePlugin)
public class ScreenTimePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ScreenTimePlugin"
    public let jsName = "ScreenTime"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestAuthorization", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getStatus", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "pickApps", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "startBlocking", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopBlocking", returnType: CAPPluginReturnPromise)
    ]

    private let store = ManagedSettingsStore()
    private let key = "st_selection_v1"

    private func loadSelection() -> FamilyActivitySelection {
        guard let data = UserDefaults.standard.data(forKey: key),
              let sel = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return sel
    }

    private func saveSelection(_ sel: FamilyActivitySelection) {
        if let data = try? PropertyListEncoder().encode(sel) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func counts(_ sel: FamilyActivitySelection) -> [String: Any] {
        ["apps": sel.applicationTokens.count,
         "sites": sel.webDomainTokens.count,
         "categories": sel.categoryTokens.count]
    }

    @objc func requestAuthorization(_ call: CAPPluginCall) {
        Task { @MainActor in
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                call.resolve(["authorized": true])
            } catch {
                call.reject("Could not get Screen Time access: \(error.localizedDescription)")
            }
        }
    }

    @objc func getStatus(_ call: CAPPluginCall) {
        var out = counts(loadSelection())
        out["authorized"] = AuthorizationCenter.shared.authorizationStatus == .approved
        call.resolve(out)
    }

    @objc func pickApps(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let presenter = self.bridge?.viewController else {
                call.reject("No view controller")
                return
            }
            var host: UIHostingController<PickerScreen>?
            host = UIHostingController(rootView: PickerScreen(selection: self.loadSelection()) { sel in
                self.saveSelection(sel)
                host?.dismiss(animated: true) {
                    var out = self.counts(sel)
                    out["authorized"] = AuthorizationCenter.shared.authorizationStatus == .approved
                    call.resolve(out)
                }
            })
            host?.isModalInPresentation = true
            presenter.present(host!, animated: true)
        }
    }

    @objc func startBlocking(_ call: CAPPluginCall) {
        let sel = loadSelection()
        let apps: Set<ApplicationToken> = sel.applicationTokens
        let sites: Set<WebDomainToken> = sel.webDomainTokens
        let cats: Set<ActivityCategoryToken> = sel.categoryTokens
        if apps.isEmpty { store.shield.applications = nil } else { store.shield.applications = apps }
        if sites.isEmpty { store.shield.webDomains = nil } else { store.shield.webDomains = sites }
        if cats.isEmpty {
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
        } else {
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>.specific(cats)
            store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy<WebDomain>.specific(cats)
        }
        call.resolve()
    }

    @objc func stopBlocking(_ call: CAPPluginCall) {
        store.clearAllSettings()
        call.resolve()
    }
}
