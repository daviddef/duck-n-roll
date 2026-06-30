//
//  EvolutionStage.swift
//  Duck-n-Roll
//
//  The character evolves as the player climbs the 30 levels. Each stage changes
//  the look (size, colour, crest) and is purely cosmetic + a size scalar that
//  the player node reads when it is (re)built.
//

import SpriteKit

struct EvolutionStage {
    let index: Int
    let name: String
    let bodyColor: SKColor
    let scale: CGFloat        // visual size multiplier
    let hasCrest: Bool        // little head plume that appears at later stages
    let hasWingTips: Bool     // wing accents for the most evolved forms

    /// The ordered list of forms. The character moves up one stage roughly every
    /// five levels, ending as the apex form for the level-30 boss fight.
    static let all: [EvolutionStage] = [
        EvolutionStage(index: 0, name: "Duckling",    bodyColor: Palette.duck,                                              scale: 0.78, hasCrest: false, hasWingTips: false),
        EvolutionStage(index: 1, name: "Fledgling",   bodyColor: SKColor(red: 1.00, green: 0.80, blue: 0.30, alpha: 1.0),  scale: 0.90, hasCrest: false, hasWingTips: false),
        EvolutionStage(index: 2, name: "Mallard",     bodyColor: SKColor(red: 0.30, green: 0.70, blue: 0.55, alpha: 1.0),  scale: 1.00, hasCrest: true,  hasWingTips: false),
        EvolutionStage(index: 3, name: "Wild Drake",  bodyColor: SKColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1.0),  scale: 1.10, hasCrest: true,  hasWingTips: true),
        EvolutionStage(index: 4, name: "Storm Goose", bodyColor: SKColor(red: 0.60, green: 0.35, blue: 0.80, alpha: 1.0),  scale: 1.20, hasCrest: true,  hasWingTips: true),
        EvolutionStage(index: 5, name: "Phoenix Fowl",bodyColor: SKColor(red: 1.00, green: 0.45, blue: 0.20, alpha: 1.0),  scale: 1.32, hasCrest: true,  hasWingTips: true),
    ]

    /// Maps a 1-based level to a stage. ~5 levels per evolution, clamped.
    static func stage(forLevel level: Int) -> EvolutionStage {
        let idx = min((max(level, 1) - 1) / 5, all.count - 1)
        return all[idx]
    }
}
