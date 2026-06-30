//
//  GameState.swift
//  MateoDuckGame
//
//  Single source of truth for meta-progression that survives between scenes and
//  app launches: coins, the highest level reached, and the permanent speed /
//  jump upgrades the player buys between levels.
//

import Foundation
import CoreGraphics

final class GameState {

    static let shared = GameState()

    private let defaults = UserDefaults.standard
    private enum Key {
        static let coins      = "mdg.coins"
        static let highest    = "mdg.highestLevel"
        static let speedTier  = "mdg.speedTier"
        static let jumpTier   = "mdg.jumpTier"
    }

    // MARK: - Persisted values

    private(set) var coins: Int {
        didSet { defaults.set(coins, forKey: Key.coins) }
    }

    /// Highest level unlocked (the player may replay anything up to here).
    private(set) var highestLevel: Int {
        didSet { defaults.set(highestLevel, forKey: Key.highest) }
    }

    /// Upgrade tiers (0...maxTier). Each tier costs more than the last.
    private(set) var speedTier: Int {
        didSet { defaults.set(speedTier, forKey: Key.speedTier) }
    }
    private(set) var jumpTier: Int {
        didSet { defaults.set(jumpTier, forKey: Key.jumpTier) }
    }

    /// The level the player is about to play. Not persisted — set by the menu.
    var currentLevel: Int = 1

    static let maxTier = 6
    static let startingLives = 3

    private init() {
        coins        = defaults.integer(forKey: Key.coins)
        highestLevel = max(1, defaults.integer(forKey: Key.highest))
        speedTier    = defaults.integer(forKey: Key.speedTier)
        jumpTier     = defaults.integer(forKey: Key.jumpTier)
    }

    // MARK: - Coins

    func addCoins(_ amount: Int) {
        guard amount != 0 else { return }
        coins = max(0, coins + amount)
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }

    // MARK: - Progression

    func levelCleared(_ level: Int) {
        if level + 1 > highestLevel {
            highestLevel = min(level + 1, LevelConfig.maxLevel)
        }
    }

    // MARK: - Upgrades

    func upgradeCost(forTier tier: Int) -> Int {
        // Tier 1 costs 100, tier 2 costs 180, ... rising.
        return 100 + tier * 80
    }

    /// Multiplier applied to the player's horizontal move speed.
    var speedMultiplier: CGFloat { 1.0 + 0.12 * CGFloat(speedTier) }

    /// Multiplier applied to jump height / hang time.
    var jumpMultiplier: CGFloat { 1.0 + 0.14 * CGFloat(jumpTier) }

    @discardableResult
    func buySpeedUpgrade() -> Bool {
        guard speedTier < GameState.maxTier else { return false }
        guard spendCoins(upgradeCost(forTier: speedTier)) else { return false }
        speedTier += 1
        return true
    }

    @discardableResult
    func buyJumpUpgrade() -> Bool {
        guard jumpTier < GameState.maxTier else { return false }
        guard spendCoins(upgradeCost(forTier: jumpTier)) else { return false }
        jumpTier += 1
        return true
    }

    #if DEBUG
    func resetAll() {
        coins = 0; highestLevel = 1; speedTier = 0; jumpTier = 0; currentLevel = 1
    }
    #endif
}
