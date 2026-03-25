import Foundation

enum ContentFilter {

    // MARK: - Username Validation

    static func isValidUsername(_ username: String) -> (valid: Bool, reason: String?) {
        let trimmed = username.trimmingCharacters(in: .whitespaces)

        if trimmed.count < 3 {
            return (false, "Username must be at least 3 characters")
        }
        if trimmed.count > 20 {
            return (false, "Username must be 20 characters or less")
        }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_.-"))
        if trimmed.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return (false, "Username can only contain letters, numbers, _ . -")
        }

        if containsProfanity(trimmed) {
            return (false, "Username contains inappropriate language")
        }

        return (true, nil)
    }

    // MARK: - Text Content Check

    static func isCleanContent(_ text: String) -> (clean: Bool, reason: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return (false, "Content cannot be empty")
        }

        if containsProfanity(trimmed) {
            return (false, "Your message contains inappropriate language. Please revise.")
        }

        return (true, nil)
    }

    // MARK: - Profanity Check

    private static func containsProfanity(_ text: String) -> Bool {
        let lower = text.lowercased()
            .replacingOccurrences(of: "0", with: "o")
            .replacingOccurrences(of: "1", with: "i")
            .replacingOccurrences(of: "3", with: "e")
            .replacingOccurrences(of: "4", with: "a")
            .replacingOccurrences(of: "5", with: "s")
            .replacingOccurrences(of: "@", with: "a")
            .replacingOccurrences(of: "$", with: "s")

        // Common slurs and profanity — keeping this list focused on the worst offenders.
        // Add more as needed. Using word boundary detection to avoid false positives.
        let blockedWords = [
            "fuck", "shit", "bitch", "ass", "damn", "dick", "pussy",
            "cock", "cunt", "whore", "slut", "bastard", "fag",
            "nigger", "nigga", "retard", "spic", "chink", "kike",
            "wetback", "cracker", "honky", "gook", "tranny",
            "kill yourself", "kys"
        ]

        // Check each blocked word with word boundary awareness
        for word in blockedWords {
            if lower.containsWord(word) {
                return true
            }
        }

        return false
    }
}

private extension String {
    /// Checks if the string contains the given word, accounting for word boundaries
    func containsWord(_ word: String) -> Bool {
        // Direct contains check for multi-word phrases
        if word.contains(" ") {
            return self.contains(word)
        }
        // For single words, check with basic boundary detection
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        return (try? NSRegularExpression(pattern: pattern, options: .caseInsensitive))?.firstMatch(
            in: self, range: NSRange(self.startIndex..., in: self)
        ) != nil
    }
}
