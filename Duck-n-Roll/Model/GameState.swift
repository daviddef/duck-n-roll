//
//  GameState.swift
//  Duck-n-Roll
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
        static let weaponTier = "mdg.weaponTier"
    }

    /// A blaster upgrade — fires energy bolts at the boulders.
    struct Weapon {
        let name: String
        let cooldown: TimeInterval   // seconds between shots
        let bolts: Int               // projectiles per shot
        let spread: CGFloat          // total fan angle (radians)
        let icon: String
    }
    static let weapons: [Weapon] = [
        Weapon(name: "Pea Shooter",   cooldown: 0.34, bolts: 1, spread: 0.0,  icon: "•"),
        Weapon(name: "Rapid Blaster", cooldown: 0.17, bolts: 1, spread: 0.0,  icon: "⚡️"),
        Weapon(name: "Twin Cannon",   cooldown: 0.26, bolts: 2, spread: 0.16, icon: "⊕"),
        Weapon(name: "Spread Gun",    cooldown: 0.30, bolts: 3, spread: 0.55, icon: "✷"),
        Weapon(name: "Auto-Cannon",   cooldown: 0.10, bolts: 2, spread: 0.20, icon: "✸"),
    ]
    static let maxWeaponTier = weapons.count - 1

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
    private(set) var weaponTier: Int {
        didSet { defaults.set(weaponTier, forKey: Key.weaponTier) }
    }

    var weapon: Weapon { GameState.weapons[min(max(0, weaponTier), GameState.maxWeaponTier)] }

    /// Use the cave home base instead of the cottage (cosmetic, persisted).
    var useCave: Bool {
        get { defaults.bool(forKey: "mdg.useCave") }
        set { defaults.set(newValue, forKey: "mdg.useCave") }
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
        weaponTier   = defaults.integer(forKey: Key.weaponTier)
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

    /// Cost to unlock the NEXT weapon (pricier than stat upgrades).
    func weaponCost(forTier tier: Int) -> Int { 200 + tier * 150 }

    /// Name of the next weapon you'd unlock, or nil if maxed.
    var nextWeaponName: String? {
        weaponTier < GameState.maxWeaponTier ? GameState.weapons[weaponTier + 1].name : nil
    }

    @discardableResult
    func buyWeaponUpgrade() -> Bool {
        guard weaponTier < GameState.maxWeaponTier else { return false }
        guard spendCoins(weaponCost(forTier: weaponTier)) else { return false }
        weaponTier += 1
        return true
    }

    #if DEBUG
    func resetAll() {
        coins = 0; highestLevel = 1; speedTier = 0; jumpTier = 0; weaponTier = 0; currentLevel = 1
    }
    #endif
}
