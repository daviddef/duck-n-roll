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

    static let tier3: [WordEntry] = [
        .init(word: "CAT", emoji: "🐱"), .init(word: "DOG", emoji: "🐶"),
        .init(word: "SUN", emoji: "☀️"), .init(word: "BUG", emoji: "🐛"),
        .init(word: "EGG", emoji: "🥚"), .init(word: "BEE", emoji: "🐝"),
        .init(word: "FOX", emoji: "🦊"), .init(word: "COW", emoji: "🐮"),
        .init(word: "PIG", emoji: "🐷"), .init(word: "OWL", emoji: "🦉"),
        .init(word: "BAT", emoji: "🦇"), .init(word: "ANT", emoji: "🐜"),
        .init(word: "HEN", emoji: "🐔"), .init(word: "BUD", emoji: "🌱")
    ]

    static let tier4: [WordEntry] = [
        .init(word: "DUCK", emoji: "🦆"), .init(word: "FROG", emoji: "🐸"),
        .init(word: "BIRD", emoji: "🐦"), .init(word: "FISH", emoji: "🐟"),
        .init(word: "NEST", emoji: "🪺"), .init(word: "LEAF", emoji: "🍃"),
        .init(word: "TREE", emoji: "🌳"), .init(word: "STAR", emoji: "⭐"),
        .init(word: "MOON", emoji: "🌙"), .init(word: "GOAT", emoji: "🐐"),
        .init(word: "BEAR", emoji: "🐻"), .init(word: "WOLF", emoji: "🐺"),
        .init(word: "SEED", emoji: "🌰")
    ]

    static let tier5: [WordEntry] = [
        .init(word: "SNAIL", emoji: "🐌"), .init(word: "EAGLE", emoji: "🦅"),
        .init(word: "TIGER", emoji: "🐯"), .init(word: "ZEBRA", emoji: "🦓"),
        .init(word: "SHEEP", emoji: "🐑"), .init(word: "MOUSE", emoji: "🐭"),
        .init(word: "SNAKE", emoji: "🐍"), .init(word: "WHALE", emoji: "🐳"),
        .init(word: "PLANT", emoji: "🌱"), .init(word: "CLOUD", emoji: "☁️"),
        .init(word: "STORM", emoji: "⛈️"), .init(word: "SHELL", emoji: "🐚")
    ]

    static let tier6: [WordEntry] = [
        .init(word: "RABBIT", emoji: "🐰"), .init(word: "MONKEY", emoji: "🐵"),
        .init(word: "TURTLE", emoji: "🐢"), .init(word: "PARROT", emoji: "🦜"),
        .init(word: "FLOWER", emoji: "🌸"), .init(word: "FOREST", emoji: "🌲"),
        .init(word: "GARDEN", emoji: "🌷"), .init(word: "PLANET", emoji: "🪐"),
        .init(word: "SPIDER", emoji: "🕷️"), .init(word: "DRAGON", emoji: "🐉")
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

    /// Deterministic single word for a "spell one word" level.
    static func word(forLevel level: Int) -> WordEntry {
        let list = tier(forLevel: level)
        return list[(level - 1) % list.count]
    }

    /// A fresh random word for streak / boss rounds (avoids repeating `previous`).
    static func randomWord(forLevel level: Int, avoiding previous: String?) -> WordEntry {
        let list = tier(forLevel: level)
        var pick = list[Int.random(in: 0..<list.count)]
        if let previous, list.count > 1 {
            var guardCount = 0
            while pick.word == previous && guardCount < 8 {
                pick = list[Int.random(in: 0..<list.count)]
                guardCount += 1
            }
        }
        return pick
    }

    /// A pool of distinct letters useful as decoys (word letters + a little noise).
    static func decoyLetters(for word: [Character]) -> [Character] {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var pool = word
        // add a few random letters for variety
        for _ in 0..<4 { pool.append(alphabet[Int.random(in: 0..<alphabet.count)]) }
        return pool
    }
}
