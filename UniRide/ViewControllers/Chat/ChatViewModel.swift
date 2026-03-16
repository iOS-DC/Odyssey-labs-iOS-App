import Foundation
import Combine

final class ChatViewModel: ObservableObject {

    @Published var messages: [ChatMessage] = []

    let rideID: String
    let rideTitle: String

    /// Other people in this ride chat (passengers + driver, minus current user)
    var participants: [UserProfile]

    private let currentUserID: String
    private let currentUserName: String

    private var cancellable: AnyCancellable?

    // MARK: - Realtime
    private let realtimeClient = SupabaseRealtimeClient()

    // MARK: - Init
    init(rideID: String, rideTitle: String, participants: [UserProfile] = []) {
        self.rideID        = rideID
        self.rideTitle     = rideTitle
        self.participants  = participants

        let me = UserDataModel.shared.getCurrentUser()
        self.currentUserID   = me?.id.uuidString ?? ""
        self.currentUserName = me?.fullName ?? "Me"

        load()
        subscribeToLocalUpdates()
        startRealtimeSubscription()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        realtimeClient.disconnect()
    }

    // MARK: - Load + Subscribe

    private func load() {
        messages = ChatDataModel.shared.messages(for: rideID)
        ChatDataModel.shared.markAsRead(rideID: rideID)
        // Also fetch from Supabase to catch messages sent while offline
        Task { await fetchFromSupabase() }
    }

    /// Fetches historical messages from Supabase and merges into the local cache.
    @MainActor
    private func fetchFromSupabase() async {
        guard let rideUUID = UUID(uuidString: rideID) else { return }
        guard let remote = try? await ChatRepository.shared.fetchMessages(rideID: rideUUID) else { return }
        
        // Bulk append with deduplication to avoid notification storm
        ChatDataModel.shared.appendContents(of: remote, to: rideID)
        
        // Reload locally to reflect merged state
        self.messages = ChatDataModel.shared.messages(for: rideID)
        ChatDataModel.shared.markAsRead(rideID: rideID)
    }

    private func subscribeToLocalUpdates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocalUpdate(_:)),
            name: .chatMessagesUpdated,
            object: nil
        )
    }

    @objc private func handleLocalUpdate(_ note: Notification) {
        guard let updated = note.object as? String, updated == rideID else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.messages = ChatDataModel.shared.messages(for: self.rideID)
            ChatDataModel.shared.markAsRead(rideID: self.rideID)
        }
    }

    // MARK: - Supabase Realtime subscription

    private func startRealtimeSubscription() {
        guard let rideUUID = UUID(uuidString: rideID) else { return }

        // Subscribe to INSERT events on messages filtered by this ride
        let channel = realtimeClient
            .channel("public:messages:ride_id=eq.\(rideUUID.uuidString)")

        channel.on("INSERT") { [weak self] record in
            guard let self else { return }
            self.handleRealtimeInsert(record)
        }

        realtimeClient.connect()
        channel.subscribe()
    }

    /// Called on the main thread when a real-time INSERT arrives from Supabase.
    private func handleRealtimeInsert(_ record: [String: Any]) {
        guard
            let idStr    = record["id"]          as? String, let id = UUID(uuidString: idStr),
            let senderID = record["sender_id"]   as? String,
            let text     = record["body"]        as? String,
            let tsStr    = record["created_at"]  as? String
        else { return }

        // Ignore our own messages — we already append them locally on send
        guard senderID != currentUserID else { return }

        // Deduplicate: if this message is already in the cache (e.g. from the
        // REST fetch on open) don't add it again
        let existing = ChatDataModel.shared.messages(for: rideID)
        guard !existing.contains(where: { $0.id == id }) else { return }

        let ts   = ISO8601DateFormatter().date(from: tsStr) ?? Date()
        let name = record["sender_name"] as? String ?? ""
        let msg  = ChatMessage(id: id, senderID: senderID, senderName: name, text: text, timestamp: ts)

        ChatDataModel.shared.append(msg, to: rideID)
        messages.append(msg)
        ChatDataModel.shared.markAsRead(rideID: rideID)
    }

    // MARK: - Send

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let cleanedText = ProfanityFilter.shared.clean(trimmed)

        let msg = ChatMessage(
            id: UUID(),
            senderID: currentUserID,
            senderName: currentUserName,
            text: cleanedText,
            timestamp: Date()
        )
        // Append locally for instant UI feedback
        ChatDataModel.shared.append(msg, to: rideID)
        messages.append(msg)

        // Persist to Supabase `messages` table
        if let rideUUID = UUID(uuidString: rideID) {
            Task {
                try? await ChatRepository.shared.sendMessage(
                    id: msg.id, // SYNC LOCAL ID WITH SERVER
                    rideID: rideUUID,
                    senderID: UUID(uuidString: currentUserID) ?? UUID(),
                    senderName: currentUserName,
                    text: cleanedText
                )
            }
        }

        scheduleAutoReply(after: trimmed)
    }

    // MARK: - Contextual Auto-Reply (demo purposes)
    private func scheduleAutoReply(after message: String) {
        let others = participants.filter { $0.id.uuidString != currentUserID }
        guard let responder = others.randomElement() else { return }
        guard Double.random(in: 0...1) < 0.70 else { return }

        let replies: [String]
        let lower = message.lowercased()

        if lower.contains("late") || lower.contains("wait") {
            replies = ["No worries, I can wait a couple minutes 🙂",
                       "Ok, just let me know when you're on your way!",
                       "Sure, I'll hold. Just please hurry 😅"]
        } else if lower.contains("where") || lower.contains("location") {
            replies = ["I'm at the main gate, near the parking 📍",
                       "Just outside the hostel block. Can you share your live location?",
                       "I can see the building from here, coming to you!"]
        } else if lower.contains("hi") || lower.contains("hello") || lower.contains("hey") {
            replies = ["Hey! 👋 See you at the pickup!",
                       "Hi! All set for the ride 🚗",
                       "Hello! Ready to go!"]
        } else if lower.contains("thanks") || lower.contains("thank") {
            replies = ["You're welcome! 😊", "No problem at all!", "Anytime! 🙏"]
        } else {
            replies = ["Got it 👍", "Ok, noted!", "Sounds good!",
                       "I'll be ready at the pickup point.", "✓ Acknowledged",
                       "Perfect, see you soon!", "Running on time 🕐",
                       "Cool, thanks for the heads up!", "Ok sure 👌", "On my way! 🏃"]
        }

        let delay = Double.random(in: 1.5...4.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            let reply = ChatMessage(
                id: UUID(),
                senderID: responder.id.uuidString,
                senderName: responder.fullName,
                text: replies.randomElement()!,
                timestamp: Date()
            )
            ChatDataModel.shared.append(reply, to: self.rideID)
            self.messages.append(reply)
        }
    }
}
