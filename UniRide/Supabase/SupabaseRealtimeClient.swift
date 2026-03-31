// SupabaseRealtimeClient.swift
// UniRide
//
// A lightweight Supabase Realtime client built on URLSessionWebSocketTask.
// Uses the Phoenix Channel protocol that Supabase Realtime speaks over WSS.
//
// Usage:
//   let client = SupabaseRealtimeClient()
//   let channel = client.channel("public:messages:ride_id=eq.<UUID>")
//   channel.on("INSERT") { payload in /* new row */ }
//   await client.connect()
//   channel.subscribe()
//
// When the view disappears:
//   client.disconnect()
//
// ─────────────────────────────────────────────────────────────────────────────
// Supabase Realtime WSS endpoint format:
//   wss://<project>.supabase.co/realtime/v1/websocket?apikey=<anon>&vsn=1.0.0
// ─────────────────────────────────────────────────────────────────────────────

import Foundation

// MARK: - Message types

typealias RealtimePayloadHandler = ([String: Any]) -> Void

// MARK: - RealtimeChannel

final class RealtimeChannel {
    let topic: String
    var onInsert: RealtimePayloadHandler?
    let schema: String
    let table: String
    let filter: String?

    // Phoenix ref counter shared with the client
    fileprivate var ref: Int = 0
    fileprivate weak var client: SupabaseRealtimeClient?

    init(topic: String, schema: String, table: String, filter: String?) {
        self.topic = topic
        self.schema = schema
        self.table = table
        self.filter = filter
    }

    /// Register a handler for INSERT events on this channel.
    @discardableResult
    func on(_ event: String, handler: @escaping RealtimePayloadHandler) -> Self {
        if event == "INSERT" { onInsert = handler }
        return self
    }

    /// Subscribe — sends a phx_join frame to the server.
    func subscribe() {
        client?.joinChannel(self)
    }
}

// MARK: - SupabaseRealtimeClient

final class SupabaseRealtimeClient: NSObject {

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var channels: [String: RealtimeChannel] = [:]
    private var refCounter = 0
    private var isConnected = false
    private var pendingJoins: [RealtimeChannel] = []   // channels waiting for connect

    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    // MARK: - Connect

    func connect() {
        guard !isConnected else { return }

        // Build the WSS URL
        let base = BackendConfig.baseURL?.absoluteString ?? ""
        let wsBase = base
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://",  with: "ws://")
        let anonKey = BackendConfig.supabaseAnonKey ?? ""
        guard let url = URL(string: "\(wsBase)/realtime/v1/websocket?apikey=\(anonKey)&vsn=1.0.0") else {
            print("[Realtime] Invalid WSS URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(SessionManager.shared.accessToken ?? anonKey)",
                         forHTTPHeaderField: "Authorization")

        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()
        isConnected = true
        startReceiving()
        startHeartbeat()
        // Flush any channels that called subscribe() before connect()
        pendingJoins.forEach { joinChannel($0) }
        pendingJoins.removeAll()
    }

    // MARK: - Disconnect

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        channels.removeAll()
    }

    // MARK: - Channel factory

    func channel(_ topic: String) -> RealtimeChannel {
        let parts = topic.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        let schema = parts.indices.contains(0) ? parts[0] : "public"
        let table = parts.indices.contains(1) ? parts[1] : "messages"
        let filter = parts.indices.contains(2) ? parts[2] : nil
        let ch = RealtimeChannel(topic: "realtime:\(topic)", schema: schema, table: table, filter: filter)
        ch.client = self
        channels[ch.topic] = ch
        return ch
    }

    // MARK: - Join

    fileprivate func joinChannel(_ channel: RealtimeChannel) {
        guard isConnected else {
            pendingJoins.append(channel)
            return
        }
        refCounter += 1
        channel.ref = refCounter

        var postgresChange: [String: Any] = [
            "event": "INSERT",
            "schema": channel.schema,
            "table": channel.table
        ]
        if let filter = channel.filter, !filter.isEmpty {
            postgresChange["filter"] = filter
        }

        let joinPayload: [String: Any] = [
            "topic":   channel.topic,
            "event":   "phx_join",
            "payload": ["config": ["broadcast": ["self": false],
                                   "presence":  ["key": ""],
                                   "postgres_changes": [postgresChange]]],
            "ref":     "\(channel.ref)"
        ]
        send(joinPayload)
    }

    // MARK: - Heartbeat (Phoenix requires periodic heartbeats)

    private func startHeartbeat() {
        Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            guard let self, self.isConnected else { return }
            self.refCounter += 1
            self.send(["topic": "phoenix", "event": "heartbeat",
                       "payload": [:] as [String: Any], "ref": "\(self.refCounter)"])
        }
    }

    // MARK: - Send

    private func send(_ dict: [String: Any]) {
        guard let data  = try? JSONSerialization.data(withJSONObject: dict),
              let text  = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(text)) { error in
            if let e = error { print("[Realtime] send error: \(e)") }
        }
    }

    // MARK: - Receive loop

    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let err):
                print("[Realtime] receive error: \(err.localizedDescription)")
            case .success(let msg):
                switch msg {
                case .string(let text):   self.handleText(text)
                case .data(let data):
                    if let t = String(data: data, encoding: .utf8) { self.handleText(t) }
                @unknown default: break
                }
                // Re-arm the receive loop
                if self.isConnected { self.startReceiving() }
            }
        }
    }

    // MARK: - Parse incoming frame

    private func handleText(_ text: String) {
        guard
            let data    = text.data(using: .utf8),
            let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let topic   = json["topic"]   as? String,
            let payload = json["payload"] as? [String: Any]
        else { return }

        // Supabase Realtime wraps the actual postgres change inside payload.data
        guard let innerData = payload["data"] as? [String: Any],
              let eventType = innerData["type"] as? String,
              eventType == "INSERT"
        else { return }

        let record = innerData["record"] as? [String: Any] ?? [:]

        // Find the subscribed channel by topic or by the realtime:* wildcard
        for (channelTopic, channel) in channels where topic == channelTopic || topic.hasPrefix("realtime:") {
            DispatchQueue.main.async {
                _ = channelTopic  // suppress warning
                channel.onInsert?(record)
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension SupabaseRealtimeClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("[Realtime] WebSocket connected")
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("[Realtime] WebSocket closed: \(closeCode.rawValue)")
        isConnected = false
    }
}
