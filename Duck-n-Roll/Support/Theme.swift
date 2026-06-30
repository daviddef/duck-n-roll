//
//  Theme.swift
//  Duck-n-Roll
//
//  Central place for colors, fonts, z-positions and physics categories so the
//  look of the game can be tuned in one spot.
//

import SpriteKit

enum Palette {
    static let skyTop     = SKColor(red: 0.45, green: 0.78, blue: 0.98, alpha: 1.0)
    static let skyBottom  = SKColor(red: 0.78, green: 0.93, blue: 1.00, alpha: 1.0)
    static let hillNear   = SKColor(red: 0.36, green: 0.66, blue: 0.32, alpha: 1.0)
    static let hillFar    = SKColor(red: 0.52, green: 0.78, blue: 0.42, alpha: 1.0)
    static let duck       = SKColor(red: 1.00, green: 0.85, blue: 0.20, alpha: 1.0)
    static let duckBeak   = SKColor(red: 0.97, green: 0.55, blue: 0.10, alpha: 1.0)
    static let boulder    = SKColor(red: 0.45, green: 0.42, blue: 0.40, alpha: 1.0)
    static let ball       = SKColor(red: 0.92, green: 0.27, blue: 0.31, alpha: 1.0)
    static let hut        = SKColor(red: 0.62, green: 0.40, blue: 0.24, alpha: 1.0)
    static let hutRoof    = SKColor(red: 0.85, green: 0.30, blue: 0.25, alpha: 1.0)
    static let coin       = SKColor(red: 1.00, green: 0.82, blue: 0.20, alpha: 1.0)
    static let warning    = SKColor(red: 0.95, green: 0.20, blue: 0.15, alpha: 1.0)
    static let projectile = SKColor(red: 0.30, green: 0.85, blue: 1.00, alpha: 1.0)
    static let ink        = SKColor(red: 0.12, green: 0.15, blue: 0.20, alpha: 1.0)
    static let panel      = SKColor(red: 0.10, green: 0.13, blue: 0.20, alpha: 0.82)
}

enum FontName {
    static let heavy = "AvenirNext-Heavy"
    static let bold  = "AvenirNext-Bold"
    static let demi  = "AvenirNext-DemiBold"
}

/// Drawing order, low to high.
enum Z {
    static let background: CGFloat = -100
    static let hill: CGFloat       = -90
    static let hut: CGFloat        = -10
    static let obstacle: CGFloat   = 10
    static let player: CGFloat     = 20
    static let projectile: CGFloat = 15
    static let effects: CGFloat    = 50
    static let hud: CGFloat        = 100
    static let overlay: CGFloat    = 200
}

/// Physics bitmasks. Collisions are handled manually in didBegin(_:).
struct PhysicsCategory {
    static let none: UInt32       = 0
    static let player: UInt32     = 0x1 << 0
    static let obstacle: UInt32   = 0x1 << 1
    static let projectile: UInt32 = 0x1 << 2
    static let boss: UInt32       = 0x1 << 3
}
