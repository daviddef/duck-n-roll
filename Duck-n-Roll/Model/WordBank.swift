//
//  WordBank.swift
//  Duck-n-Roll
//
//  Built-in spelling words, grouped into difficulty tiers that grow from 3-letter
//  words up to 6, themed around the duck / nature world. Each word carries an
//  emoji used in the "you spelled it!" celebration. Word selection is
//  deterministic per level so a given level always teaches the same word.
//

import Foundation

struct WordEntry {
    let word: String
    let emoji: String
    var letters: [Character] { Array(word.uppercased()) }
}

enum WordBank {

    // Tier 1 — 3-letter words (levels 1–5). Big, friendly, very common.
    static let tier3: [WordEntry] = [
        .init(word: "CAT", emoji: "🐱"), .init(word: "DOG", emoji: "🐶"),
        .init(word: "SUN", emoji: "☀️"), .init(word: "BUG", emoji: "🐛"),
        .init(word: "EGG", emoji: "🥚"), .init(word: "BEE", emoji: "🐝"),
        .init(word: "FOX", emoji: "🦊"), .init(word: "COW", emoji: "🐮"),
        .init(word: "PIG", emoji: "🐷"), .init(word: "OWL", emoji: "🦉"),
        .init(word: "BAT", emoji: "🦇"), .init(word: "ANT", emoji: "🐜"),
        .init(word: "HEN", emoji: "🐔"), .init(word: "BUS", emoji: "🚌"),
        .init(word: "HAT", emoji: "🎩"), .init(word: "CUP", emoji: "🥤"),
        .init(word: "BED", emoji: "🛏️"), .init(word: "BOX", emoji: "📦"),
        .init(word: "PEN", emoji: "🖊️"), .init(word: "FAN", emoji: "🪭"),
        .init(word: "WEB", emoji: "🕸️"), .init(word: "MAP", emoji: "🗺️"),
        .init(word: "JAM", emoji: "🍓"), .init(word: "NUT", emoji: "🥜"),
        .init(word: "KEY", emoji: "🔑"), .init(word: "CAR", emoji: "🚗"),
        .init(word: "PIE", emoji: "🥧"), .init(word: "BAG", emoji: "🎒"),
        .init(word: "ICE", emoji: "🧊"), .init(word: "CAP", emoji: "🧢")
    ]

    // Tier 2 — 4-letter words (levels 6–10).
    static let tier4: [WordEntry] = [
        .init(word: "DUCK", emoji: "🦆"), .init(word: "FROG", emoji: "🐸"),
        .init(word: "BIRD", emoji: "🐦"), .init(word: "FISH", emoji: "🐟"),
        .init(word: "NEST", emoji: "🪺"), .init(word: "LEAF", emoji: "🍃"),
        .init(word: "TREE", emoji: "🌳"), .init(word: "STAR", emoji: "⭐"),
        .init(word: "MOON", emoji: "🌙"), .init(word: "GOAT", emoji: "🐐"),
        .init(word: "BEAR", emoji: "🐻"), .init(word: "WOLF", emoji: "🐺"),
        .init(word: "CAKE", emoji: "🍰"), .init(word: "MILK", emoji: "🥛"),
        .init(word: "BOAT", emoji: "⛵"), .init(word: "KITE", emoji: "🪁"),
        .init(word: "DOOR", emoji: "🚪"), .init(word: "BALL", emoji: "⚽"),
        .init(word: "RING", emoji: "💍"), .init(word: "DRUM", emoji: "🥁"),
        .init(word: "BELL", emoji: "🔔"), .init(word: "CORN", emoji: "🌽"),
        .init(word: "SOCK", emoji: "🧦"), .init(word: "BOOK", emoji: "📚"),
        .init(word: "GIFT", emoji: "🎁"), .init(word: "LAMP", emoji: "💡")
    ]

    // Tier 3 — 5-letter words (levels 11–20).
    static let tier5: [WordEntry] = [
        .init(word: "SNAIL", emoji: "🐌"), .init(word: "EAGLE", emoji: "🦅"),
        .init(word: "TIGER", emoji: "🐯"), .init(word: "ZEBRA", emoji: "🦓"),
        .init(word: "SHEEP", emoji: "🐑"), .init(word: "MOUSE", emoji: "🐭"),
        .init(word: "SNAKE", emoji: "🐍"), .init(word: "WHALE", emoji: "🐳"),
        .init(word: "PLANT", emoji: "🌱"), .init(word: "CLOUD", emoji: "☁️"),
        .init(word: "SHELL", emoji: "🐚"), .init(word: "HORSE", emoji: "🐴"),
        .init(word: "KOALA", emoji: "🐨"), .init(word: "PANDA", emoji: "🐼"),
        .init(word: "CHICK", emoji: "🐤"), .init(word: "LEMON", emoji: "🍋"),
        .init(word: "APPLE", emoji: "🍎"), .init(word: "GRAPE", emoji: "🍇"),
        .init(word: "TRAIN", emoji: "🚂"), .init(word: "ROBOT", emoji: "🤖"),
        .init(word: "HEART", emoji: "❤️"), .init(word: "CANDY", emoji: "🍬")
    ]

    // Tier 4 — 6-letter words (levels 21–30).
    static let tier6: [WordEntry] = [
        .init(word: "RABBIT", emoji: "🐰"), .init(word: "MONKEY", emoji: "🐵"),
        .init(word: "TURTLE", emoji: "🐢"), .init(word: "PARROT", emoji: "🦜"),
        .init(word: "FLOWER", emoji: "🌸"), .init(word: "FOREST", emoji: "🌲"),
        .init(word: "GARDEN", emoji: "🌷"), .init(word: "PLANET", emoji: "🪐"),
        .init(word: "SPIDER", emoji: "🕷️"), .init(word: "DRAGON", emoji: "🐉"),
        .init(word: "ORANGE", emoji: "🍊"), .init(word: "BANANA", emoji: "🍌"),
        .init(word: "CARROT", emoji: "🥕"), .init(word: "ROCKET", emoji: "🚀"),
        .init(word: "CASTLE", emoji: "🏰"), .init(word: "PENCIL", emoji: "✏️"),
        .init(word: "GUITAR", emoji: "🎸"), .init(word: "COOKIE", emoji: "🍪")
    ]

    /// The tier list appropriate for a level.
    static func tier(forLevel level: Int) -> [WordEntry] {
        switch level {
        case ...5:    return tier3
        case 6...10:  return tier4
        case 11...20: return tier5
        default:      return tier6
        }
    }

    /// Number of letters in this level's words (for "spell a 3-letter word!" hints).
    static func wordLength(forLevel level: Int) -> Int {
        tier(forLevel: level).first?.word.count ?? 3
    }

    /// A random, level-appropriate word that avoids anything in `recent`
    /// (falls back to the whole tier if everything's been seen lately).
    static func randomWord(forLevel level: Int, avoiding recent: [String]) -> WordEntry {
        let list = tier(forLevel: level)
        let fresh = list.filter { !recent.contains($0.word) }
        let pool = fresh.isEmpty ? list : fresh
        return pool[Int.random(in: 0..<pool.count)]
    }

    /// Decoy letters for "wrong" boulders — mostly random letters from the whole
    /// alphabet (so kids actually have to read), with the word's own letters mixed
    /// in for a little familiarity.
    static func decoyLetters(for word: [Character]) -> [Character] {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var pool = alphabet            // every letter is fair game
        pool.append(contentsOf: word)  // slight bias toward the word's own letters
        pool.append(contentsOf: word)
        return pool
    }
}
