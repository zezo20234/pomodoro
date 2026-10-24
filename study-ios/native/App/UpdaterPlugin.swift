import UIKit
import Capacitor

/// Opens a link in Safari (used by the "Update" popup).
@objc(UpdaterPlugin)
public class UpdaterPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "UpdaterPlugin"
    public let jsName = "Updater"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "openUrl", returnType: CAPPluginReturnPromise)
    ]

    @objc func openUrl(_ call: CAPPluginCall) {
        guard let s = call.getString("url"), let url = URL(string: s),
              url.scheme == "https" || url.scheme == "http" else {
            call.reject("Invalid URL")
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { ok in
                call.resolve(["opened": ok])
            }
        }
    }
}
