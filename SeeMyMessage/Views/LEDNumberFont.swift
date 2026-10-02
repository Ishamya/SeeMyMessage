import Foundation

extension LEDFont {
    /// Digit + punctuation bitmaps (split to keep files small).
    static let digitsAndPunctuation: [Character: [String]] = [
        "0": ["01110","10001","10011","10101","11001","10001","01110"],
        "1": ["00100","01100","00100","00100","00100","00100","01110"],
        "2": ["01110","10001","00001","00110","01000","10000","11111"],
        "3": ["11111","00010","00100","00010","00001","10001","01110"],
        "4": ["00010","00110","01010","10010","11111","00010","00010"],
        "5": ["11111","10000","11110","00001","00001","10001","01110"],
        "6": ["00110","01000","10000","11110","10001","10001","01110"],
        "7": ["11111","00001","00010","00100","01000","01000","01000"],
        "8": ["01110","10001","10001","01110","10001","10001","01110"],
        "9": ["01110","10001","10001","01111","00001","00010","01100"],
        ".": ["00000","00000","00000","00000","00000","01100","01100"],
        ",": ["00000","00000","00000","00000","01100","00100","01000"],
        "!": ["00100","00100","00100","00100","00100","00000","00100"],
        "?": ["01110","10001","00001","00010","00100","00000","00100"],
        "-": ["00000","00000","00000","11111","00000","00000","00000"],
        "_": ["00000","00000","00000","00000","00000","00000","11111"],
        ":": ["00000","01100","01100","00000","01100","01100","00000"],
        "/": ["00001","00010","00010","00100","01000","01000","10000"],
        "'": ["00100","00100","01000","00000","00000","00000","00000"],
        "(": ["00010","00100","01000","01000","01000","00100","00010"],
        ")": ["01000","00100","00010","00010","00010","00100","01000"],
    ]

    /// 35-bit mask for a 5x7 glyph. Bit (row * 5 + col) = lit.
    /// Precomputed once per glyph so per-frame rendering and
    /// normalization never touch strings or dictionaries.
    typealias Mask = UInt64

    /// Masks keyed by character. Built once at startup from the
    /// string bitmaps above; rendering reads only this table.
    static let masks: [Character: Mask] = {
        var table: [Character: Mask] = [:]
        table.reserveCapacity(glyphs.count + digitsAndPunctuation.count + 1)
        for (key, rows) in glyphs {
            table[key] = mask(for: rows)
        }
        for (key, rows) in digitsAndPunctuation {
            table[key] = mask(for: rows)
        }
        table[" "] = 0
        return table
    }()

    /// Placeholder mask for unsupported chars (incl. emoji).
    static let placeholderMask: Mask = mask(for: placeholder)

    /// Blank mask for the space character.
    static let spaceMask: Mask = 0

    /// Converts 7 strings of 5 "0"/"1" into a 35-bit mask.
    private static func mask(for rows: [String]) -> Mask {
        var mask: Mask = 0
        for row in 0..<min(rows.count, LEDStyle.rows) {
            let line = Array(rows[row])
            for col in 0..<min(line.count, LEDStyle.columns) {
                if line[col] == "1" {
                    mask |= (1 as Mask) << (row * LEDStyle.columns + col)
                }
            }
        }
        return mask
    }

    /// Lowercase renders as uppercase by design.
    static func normalized(_ message: String) -> String {
        message.uppercased()
    }

    /// Normalized characters for rendering/measurement.
    /// One uppercase conversion per message, not per character.
    static func normalizedChars(_ message: String) -> [Character] {
        Array(normalized(message))
    }

    /// Bitmap rows for one char. Unknown chars (incl. emoji)
    /// get the placeholder instead of vanishing.
    static func rows(for character: Character) -> [String] {
        if character == " " { return space }
        let key = Character(String(character).uppercased())
        if let rows = glyphs[key] { return rows }
        if let rows = digitsAndPunctuation[key] { return rows }
        return placeholder
    }

    /// Bitmask for one NORMALIZED (already uppercased) character.
    /// Single dictionary lookup; no string conversion per dot.
    static func mask(forNormalized character: Character) -> Mask {
        if character == " " { return spaceMask }
        return masks[character] ?? placeholderMask
    }
}
