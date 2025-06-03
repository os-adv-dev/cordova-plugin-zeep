import Foundation
import ZIPFoundation

@objc(Zeep)
class Zeep: CDVPlugin {

    // MARK: - Resolve 'file://' or raw paths
    func resolveFilePath(from string: String) -> String {
        if string.hasPrefix("file://") {
            return URL(string: string)?.path ?? string
        }
        return string
    }

    // MARK: - ZIP
    @objc(zip:)
    func zip(command: CDVInvokedUrlCommand) {
        guard let fromPath = command.argument(at: 0) as? String,
              let toPath = command.argument(at: 1) as? String else {
            self.commandDelegate.send(
                CDVPluginResult(status: .error, messageAs: "❌ Invalid arguments"),
                callbackId: command.callbackId
            )
            return
        }

        let fromURL = URL(fileURLWithPath: resolveFilePath(from: fromPath))
        let toURL = URL(fileURLWithPath: resolveFilePath(from: toPath))

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if FileManager.default.fileExists(atPath: toURL.path) {
                    try FileManager.default.removeItem(at: toURL)
                }

                try FileManager.default.zipItem(
                    at: fromURL,
                    to: toURL,
                    shouldKeepParent: false
                )

                let result = CDVPluginResult(status: .ok, messageAs: "✅ zip completed")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                let result = CDVPluginResult(
                    status: .error,
                    messageAs: "❌ zip error: \(error.localizedDescription)"
                )
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    // MARK: - UNZIP
    @objc(unzip:)
    func unzip(command: CDVInvokedUrlCommand) {
        guard let fromPath = command.argument(at: 0) as? String,
              let toPath = command.argument(at: 1) as? String else {
            self.commandDelegate.send(
                CDVPluginResult(status: .error, messageAs: "❌ Invalid arguments"),
                callbackId: command.callbackId
            )
            return
        }

        let fromURL = URL(fileURLWithPath: resolveFilePath(from: fromPath))
        let toURL = URL(fileURLWithPath: resolveFilePath(from: toPath))

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if FileManager.default.fileExists(atPath: toURL.path) {
                    try FileManager.default.removeItem(at: toURL)
                }

                try FileManager.default.createDirectory(at: toURL, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: fromURL, to: toURL)

                let result = CDVPluginResult(status: .ok, messageAs: "✅ Unzip completed successfully.")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            } catch {
                let result = CDVPluginResult(
                    status: .error,
                    messageAs: "❌ Unzip error: \(error.localizedDescription)"
                )
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }
}