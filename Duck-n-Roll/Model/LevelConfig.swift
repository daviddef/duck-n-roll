//
//  LevelConfig.swift
//  Duck-n-Roll
//
//  Data-driven difficulty. A single function derives every level (1...30) from
//  smooth curves, so balancing the whole game is a matter of tweaking constants
//  here. Level 30 is flagged as the boss encounter.
//

import Foundation
import CoreGraphics

/// How a level is won.
enum LevelMode {
    case word    // spell one target word -> advance
    case streak  // spell as many words as possible before the timer ends
    case boss    // correct letters chip the boss down
}

struct LevelConfig {
    let level: Int
    let isBoss: Bool
    let mode: LevelMode

    /// Seconds between obstacle spawns (smaller = busier).
    let spawnInterval: TimeInterval
    /// How fast obstacles roll down the hill (points/second at the near plane).
    let obstacleSpeed: CGFloat
    /// Chance [0,1] that a spawned obstacle is a fast "ball" vs a heavy boulder.
    let ballChance: CGFloat
    /// Seconds the player must survive (avoid obstacles) to clear the level.
    let duration: TimeInterval
    /// Seconds between earthquake events; warning is `quakeWarning` long.
    let quakeInterval: TimeInterval
    let quakeWarning: TimeInterval
    /// Whether the shoot weapon is unlocked for this level onward.
    let shootingUnlocked: Bool
    /// Coins awarded for clearing the level.
    let clearBonus: Int

    static let maxLevel = 30

    static func config(for level: Int) -> LevelConfig {
        let lvl = max(1, min(level, maxLevel))
        let t = CGFloat(lvl - 1) / CGFloat(maxLevel - 1)   // 0...1 progression
        let boss = lvl == maxLevel
        // Every 5th level (5,10,15,20,25) is a streak "evolution challenge".
        let streak = !boss && lvl % 5 == 0
        let mode: LevelMode = boss ? .boss : (streak ? .streak : .word)

        // Difficulty curves — gentle, since the player is also reading & aiming.
        let spawn   = TimeInterval(2.1 - 1.1 * Double(t))            // 2.1s -> 1.0s
        let speed   = 150.0 + 300.0 * t                             // 150 -> 450 pts/s
        let balls   = 0.10 + 0.40 * t                               // few balls early
        let dur      = TimeInterval(22 + 10 * Double(t))            // streak base
        let quakeInt = TimeInterval(15 - 4 * Double(t))             // quakes get frequent
        let warn     = TimeInterval(3.0 - 0.9 * Double(t))          // less warning later

        return LevelConfig(
            level: lvl,
            isBoss: boss,
            mode: mode,
            spawnInterval: boss ? 0.95 : spawn,
            obstacleSpeed: boss ? 430 : speed,
            // Fewer balls now that lettered boulders carry the gameplay.
            ballChance: boss ? 0.4 : balls * 0.7,
            duration: streak ? TimeInterval(28 + 8 * Double(t)) : (boss ? 90 : dur),
            quakeInterval: boss ? 11 : quakeInt,
            quakeWarning: boss ? 2.0 : warn,
            shootingUnlocked: true,
            clearBonus: 50 + lvl * 10
        )
    }
}
