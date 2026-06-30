//
//  ObstacleNode.swift
//  Duck-n-Roll
//
//  Boulders and balls that roll down the hill toward the player, drawn with
//  shaded textures (glossy sphere / cracked rock). They grow as they approach to
//  fake the hill's perspective; the GameScene drives their motion and a separate
//  ground shadow telegraphs where each will arrive.
//

import SpriteKit

enum ObstacleKind {
    case boulder   // heavy + slower, low to the ground -> can be JUMPED over
    case ball      // fast + bouncy -> must be DODGED or SHOT (cannot be jumped)

    var canBeJumped: Bool { self == .boulder }
    var hitPoints: Int { self == .boulder ? 2 : 1 }
    var coinReward: Int { self == .boulder ? 3 : 2 }
}

final class ObstacleNode: SKNode {

    let kind: ObstacleKind
    private(set) var health: Int
    var progress: CGFloat = 0
    var laneX: CGFloat = 0
    var rollSpeed: CGFloat
    var scored = false

    private let art: SKSpriteNode
    private let baseColor: SKColor

    /// Spelling letter carried by this boulder (nil = plain hazard).
    let letter: Character?

    static let ballDiameter: CGFloat = 46
    static let boulderDiameter: CGFloat = 56

    init(kind: ObstacleKind, speed: CGFloat, letter: Character? = nil) {
        self.kind = kind
        self.health = kind.hitPoints
        self.rollSpeed = speed
        self.letter = letter

        switch kind {
        case .ball:
            baseColor = Palette.ball
            art = SKSpriteNode(texture: TextureFactory.glossySphere(
                diameter: ObstacleNode.ballDiameter, base: Palette.ball, key: "ball"))
        case .boulder:
            baseColor = Palette.boulder
            art = SKSpriteNode(texture: TextureFactory.boulder(diameter: ObstacleNode.boulderDiameter))
        }

        super.init()

        // Ground shadow (doesn't rotate) — gives depth and telegraphs the lane.
        let d = (kind == .ball ? ObstacleNode.ballDiameter : ObstacleNode.boulderDiameter)
        let shadow = SKSpriteNode(texture: TextureFactory.softShadow(diameter: d * 1.5))
        shadow.position = CGPoint(x: 0, y: -d * 0.52)
        shadow.yScale = 0.4
        shadow.alpha = 0.5
        shadow.zPosition = -1
        addChild(shadow)

        addChild(art)

        // Tumble while rolling toward the player.
        let spin = SKAction.rotate(byAngle: kind == .boulder ? -2 * .pi : -2 * .pi,
                                   duration: kind == .boulder ? 1.1 : 0.6)
        art.run(.repeatForever(spin))

        // Letter badge — stays upright (not a child of the spinning art) so it
        // is always readable as the boulder rolls.
        if let letter {
            let badgeR = d * 0.34
            let badge = SKShapeNode(circleOfRadius: badgeR)
            badge.fillColor = SKColor(red: 0.99, green: 0.96, blue: 0.86, alpha: 0.96)
            badge.strokeColor = SKColor(red: 0.35, green: 0.26, blue: 0.16, alpha: 1)
            badge.lineWidth = 3
            badge.zPosition = 1
            addChild(badge)
            let glyph = SKLabelNode(fontNamed: FontName.heavy)
            glyph.text = String(letter)
            glyph.fontSize = badgeR * 1.5
            glyph.fontColor = SKColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 1)
            glyph.verticalAlignmentMode = .center
            glyph.horizontalAlignmentMode = .center
            glyph.zPosition = 2
            addChild(glyph)
        }

        let r = (kind == .ball ? ObstacleNode.ballDiameter : ObstacleNode.boulderDiameter) / 2
        let pb = SKPhysicsBody(circleOfRadius: r)
        pb.isDynamic = true
        pb.affectedByGravity = false
        pb.categoryBitMask = PhysicsCategory.obstacle
        pb.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        pb.collisionBitMask = PhysicsCategory.none
        physicsBody = pb
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Returns true if destroyed.
    @discardableResult
    func takeHit() -> Bool {
        health -= 1
        art.run(.sequence([
            .group([.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.04),
                    .scale(to: art.xScale * 1.12, duration: 0.04)]),
            .group([.colorize(withColorBlendFactor: 0, duration: 0.08),
                    .scale(to: art.xScale, duration: 0.08)])
        ]))
        return health <= 0
    }
}
