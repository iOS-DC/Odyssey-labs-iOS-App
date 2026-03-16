import Foundation

/// A reusable utility to filter and censor abusive language.
final class ProfanityFilter {
    
    static let shared = ProfanityFilter()
    
    /// List of abusive or curse words to filter.
    private let badWords = [
        "fuck", "motherfucker", "shit", "bitch", "asshole", 
        "bastard", "dick", "pussy", "slut", "whore", 
        "idiot", "stupid"
    ]
    
    private init() {}
    
    /**
     Cleans the input text by replacing detected curse words with an equal length of '*' characters.
     - Parameter text: The raw input string from the user.
     - Returns: A sanitized string with profanity censored.
     */
    func clean(_ text: String) -> String {
        var sanitized = text
        
        // We use a regex for each bad word to ensure we match word boundaries
        // and handle case-insensitivity.
        for word in badWords {
            // \b ensures we match "fuck" but not "buckfuck" (if that were a word)
            // though for some bad words, partial matches might be desired.
            // Requirement says "fuck", "motherfucker" etc.
            let pattern = "\\b\(word)\\b"
            
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: sanitized.utf16.count)
                
                // Find all matches
                let matches = regex.matches(in: sanitized, options: [], range: range)
                
                // Replace matches from back to front to avoid range shifts
                for match in matches.reversed() {
                    let matchRange = match.range
                    if let swifterRange = Range(matchRange, in: sanitized) {
                        let replacement = String(repeating: "*", count: matchRange.length)
                        sanitized.replaceSubrange(swifterRange, with: replacement)
                    }
                }
            } catch {
                print("Regex error for word \(word): \(error)")
            }
        }
        
        return sanitized
    }
}
