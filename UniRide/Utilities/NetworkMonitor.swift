// NetworkMonitor.swift
// UniRide
// Wraps NWPathMonitor to expose a shared isConnected flag and post connectivity changes.

import Foundation
import Network

extension Notification.Name {
    static let connectivityChanged = Notification.Name("connectivityChanged")
}

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue   = DispatchQueue(label: "NetworkMonitor", qos: .background)

    private(set) var isConnected: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            guard connected != self.isConnected else { return }
            self.isConnected = connected
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .connectivityChanged,
                    object: nil,
                    userInfo: ["isConnected": connected]
                )
            }
        }
        monitor.start(queue: queue)
    }
}
