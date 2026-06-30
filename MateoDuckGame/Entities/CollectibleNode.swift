//
//  CollectibleNode.swift
//  MateoDuckGame
//
//  Tokens — coins, candy and gems — that appear up the hill. The player runs up
//  to grab them (risk: obstacles up there, and being far from the hut when a
//  quake hits) for escalating coin rewards.
//

import SpriteKit

enum CollectibleKind: CaseIterable {
    case coin, candy, gem

    var value: Int {
        switch self {
        case .coin:  return 5
        case .candy: return 20
        case .gem:   return 50
        }
    }
    var tint: SKColor {
        switch self {
        case .coin:  return Palette.coin
        case .candy: return SKColor(red: 1.0, green: 0.43, blue: 0.66, alpha: 1)
        case .gem:   return SKColor(red: 0.30, green: 0.78, blue: 1.0, alpha: 1)
        }
    }

    /// Weighted random pick — coins common, gems rare.
    static func weightedRandom() -> CollectibleKind {
        let roll = CGFloat.random(in: 0...1)
        if roll < 0.58 { return .coin }
        if roll < 0.88 { return .candy }
        return .gem
    }
}

final class CollectibleNode: SKNode {

    let kind: CollectibleKind
    var collected = false
    var life: TimeInterval

    /// Pickup radius in scene points.
    let pickupRadius: CGFloat = 40

    init(kind: CollectibleKind, lifetime: TimeInterval = 5.5) {
        self.kind = kind
        self.life = lifetime
        super.init()

        let art: SKSpriteNode
        switch kind {
        case .coin:  art = SKSpriteNode(texture: TextureFactory.coin(diameter: 34))
        case .candy: art = SKSpriteNode(texture: TextureFactory.candy(diameter: 34))
        case .gem:   art = SKSpriteNode(texture: TextureFactory.gem(diameter: 36))
        }
        addChild(art)

        // sparkle ring to draw the eye
        let ring = SKShapeNode(circleOfRadius: 26)
        ring.strokeColor = kind.tint.withAlphaComponent(0.6)
        ring.fillColor = .clear
        ring.lineWidth = 2
        ring.glowWidth = 3
        ring.zPosition = -1
        addChild(ring)
        ring.run(.repeatForever(.sequence([
            .group([.scale(to: 1.25, duration: 0.7), .fadeAlpha(to: 0.1, duration: 0.7)]),
            .group([.scale(to: 1.0, duration: 0.01), .fadeAlpha(to: 0.6, duration: 0.01)]),
            .wait(forDuration: 0.3)
        ])))

        // gentle bob + spin shimmer
        let bob = SKAction.sequence([.moveBy(x: 0, y: 8, duration: 0.8),
                                     .moveBy(x: 0, y: -8, duration: 0.8)])
        bob.timingMode = .easeInEaseOut
        art.run(.repeatForever(bob))
        if kind == .coin {
            art.run(.repeatForever(.sequence([
                .scaleX(to: 0.3, duration: 0.6), .scaleX(to: 1.0, duration: 0.6), .wait(forDuration: 0.6)])))
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
