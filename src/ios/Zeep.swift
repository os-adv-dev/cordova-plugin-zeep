import Foundation
import ZIPFoundation
import Cordova

@objc(Zeep)
class Zeep: CDVPlugin {

    @objc(zip:)
    func zip(command: CDVInvokedUrlCommand) {
        guard let fromPath = command.argument(at: 0) as? String,
              let toPath = command.argument(at: 1) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: .error, messageAs: "Invalid arguments"), callbackId: command.callbackId)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fromURL = URL(fileURLWithPath: fromPath)
                let toURL = URL(fileURLWithPath: toPath)

                try FileManager.default.zipItem(at: fromURL, to: toURL, shouldKeepParent: false)

                let result = CDVPluginResult(status: .ok, messageAs: "✅ zip completed")
                self.commandDelegate.send(result, callbackId: command.callbackId)

            } catch {
                let result = CDVPluginResult(status: .error, messageAs: "❌ zip error: \(error.localizedDescription)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    @objc(unzip:)
    func unzip(command: CDVInvokedUrlCommand) {
        guard let fromPath = command.argument(at: 0) as? String,
              let toPath = command.argument(at: 1) as? String else {
            self.commandDelegate.send(CDVPluginResult(status: .error, messageAs: "Invalid arguments"), callbackId: command.callbackId)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fromURL = URL(fileURLWithPath: fromPath)
                let toURL = URL(fileURLWithPath: toPath)

                try FileManager.default.createDirectory(at: toURL, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: fromURL, to: toURL)

                let result = CDVPluginResult(status: .ok, messageAs: "✅ unzip completed")
                self.commandDelegate.send(result, callbackId: command.callbackId)

            } catch {
                let result = CDVPluginResult(status: .error, messageAs: "❌ unzip error: \(error.localizedDescription)")
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }
}