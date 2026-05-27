import UIKit

extension UIImageView {
    /// Loads from a remote URL if `nameOrURL` starts with "http", otherwise falls back to a named asset.
    func loadImage(from nameOrURL: String, placeholder: UIImage? = UIImage(systemName: "photo")) {
        if nameOrURL.hasPrefix("http://") || nameOrURL.hasPrefix("https://") {
            image = placeholder
            backgroundColor = .systemGray5
            Task {
                guard let url = URL(string: nameOrURL),
                      let (data, _) = try? await URLSession.shared.data(from: url),
                      let loaded = UIImage(data: data) else { return }
                await MainActor.run {
                    self.image = loaded
                    self.backgroundColor = .clear
                }
            }
        } else {
            image = UIImage(named: nameOrURL) ?? placeholder
        }
    }
}
