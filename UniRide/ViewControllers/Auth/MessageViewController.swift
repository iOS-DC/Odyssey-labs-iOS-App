import UIKit

class MessageViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!

    // MARK: - Data
    private var messages: [Message] = [
        Message(senderId: "passenger", text: "Hi, is seat available?", time: "12:01 PM"),
        Message(senderId: "driver", text: "Yes, one seat is available.", time: "12:02 PM"),
        Message(senderId: "passenger", text: "Okay, I will book it.", time: "12:03 PM")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Messages"

        routeLabel.text = "Delhi → Chandigarh"
        dateLabel.text = "Mon, Dec 18 • 10:00 AM"

        // TableView setup
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        // 🔑 INPUT BAR LOGIC (THIS WAS MISSING)
        sendButton.isEnabled = false

        messageTextField.addTarget(
            self,
            action: #selector(textDidChange),
            for: .editingChanged
        )
    }

    // MARK: - Text Change
    @objc private func textDidChange() {
        let text = messageTextField.text ?? ""
        sendButton.isEnabled = !text.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Send Action
    @IBAction func sendTapped(_ sender: UIButton) {
        guard let text = messageTextField.text,
              !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newMessage = Message(
            senderId: "passenger",
            text: text,
            time: currentTime()
        )

        messages.append(newMessage)
        messageTextField.text = ""
        sendButton.isEnabled = false

        tableView.reloadData()
        scrollToBottom()
    }

    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    private func scrollToBottom() {
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

// MARK: - TableView DataSource
extension MessageViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "MessageCell",
            for: indexPath
        ) as! MessageCell

        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

