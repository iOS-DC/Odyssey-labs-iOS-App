import SwiftUI

struct GroupChatView: View {

    @ObservedObject var viewModel: ChatViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { idx, message in
                                // ── Date separator ──
                                if idx == 0 || !Calendar.current.isDate(
                                    message.timestamp,
                                    inSameDayAs: viewModel.messages[idx - 1].timestamp
                                ) {
                                    dateSeparator(for: message.timestamp)
                                        .padding(.vertical, 8)
                                }

                                MessageBubble(message: message, timeFormatter: timeFormatter)
                                    .padding(.bottom, 4)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let last = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                // MARK: - Input Bar
                inputBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text(viewModel.rideTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                        Text("Group Chat · \(viewModel.participants.count + 1) people")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Date Separator
    private func dateSeparator(for date: Date) -> some View {
        HStack {
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 0.5)
            Text(relativeDateString(date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .fixedSize()
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 0.5)
        }
        .padding(.horizontal, 4)
    }

    private func relativeDateString(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date)     { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return headerFormatter.string(from: date)
    }

    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $inputText, axis: .vertical)
                .focused($isInputFocused)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(AppDesign.Color.border), lineWidth: 1)
                )

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color(AppDesign.Color.textTertiary)
                                     : Color(AppDesign.Color.success))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            .animation(.easeInOut(duration: 0.15), value: inputText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: -2)
        )
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""
        viewModel.sendMessage(text)
    }
}

// MARK: - Message Bubble
private struct MessageBubble: View {

    let message: ChatMessage
    let timeFormatter: DateFormatter

    var body: some View {
        HStack {
            if message.isCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 3) {
                // Sender name (only for others)
                if !message.isCurrentUser {
                    Text(message.senderName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }

                // Bubble
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(message.isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isCurrentUser ? Color(AppDesign.Color.primary) : Color(AppDesign.Color.surfaceElevated))
                    .clipShape(BubbleShape(isCurrentUser: message.isCurrentUser))
                    .contextMenu {
                        if !message.isCurrentUser {
                            Button(role: .destructive) {
                                reportMessage()
                            } label: {
                                Label("Report Message", systemImage: "flag")
                            }
                        }
                    }

                // Timestamp
                Text(timeFormatter.string(from: message.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(message.isCurrentUser ? .trailing : .leading, 4)
            }

            if !message.isCurrentUser { Spacer(minLength: 60) }
        }
    }

    private func reportMessage() {
        guard let topVC = UIApplication.shared.topViewController() else { return }
        guard let senderUUID = UUID(uuidString: message.senderID) else { return }
        
        SafetyHelper.shared.showReportUI(
            from: topVC,
            reportedUserID: senderUUID,
            contentType: .chatMessage,
            contentID: message.id
        )
    }
}

// MARK: - Bubble Shape (one corner flat)
private struct BubbleShape: Shape {

    let isCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        let flatCorner: CGFloat = 4

        var path = Path()

        if isCurrentUser {
            // Flat bottom-right corner
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - flatCorner))
            path.addArc(center: CGPoint(x: rect.maxX - flatCorner, y: rect.maxY - flatCorner),
                        radius: flatCorner, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                        radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            // Flat bottom-left corner
            path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                        radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + flatCorner, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + flatCorner, y: rect.maxY - flatCorner),
                        radius: flatCorner, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                        radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
#Preview {
    GroupChatView(
        viewModel: ChatViewModel(
            rideID: "preview",
            rideTitle: "Downtown → Airport"
        )
    )
}
