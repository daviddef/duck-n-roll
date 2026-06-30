//
//  BossNode.swift
//  Duck-n-Roll
//
//  The level-30 boss: a hulking boulder-golem at the top of the hill. The player
//  must dodge its barrages and shoot it down in the final punch-up.
//

import SpriteKit

final class BossNode: SKNode {

    private(set) var maxHealth: Int
    private(set) var health: Int
    private let bodyShape: SKShapeNode
    private let healthBarBG: SKShapeNode
    private let healthBarFill: SKSpriteNode
    private let barWidth: CGFloat = 240

    var isDefeated: Bool { health <= 0 }

    init(maxHealth: Int) {
        self.maxHealth = maxHealth
        self.health = maxHealth

        bodyShape = SKShapeNode(path: BossNode.bodyPath())
        bodyShape.fillColor = SKColor(red: 0.36, green: 0.33, blue: 0.40, alpha: 1.0)
        bodyShape.strokeColor = SKColor(red: 0.22, green: 0.20, blue: 0.26, alpha: 1.0)
        bodyShape.lineWidth = 4

        healthBarBG = SKShapeNode(rectOf: CGSize(width: barWidth, height: 16), cornerRadius: 8)
        healthBarBG.fillColor = Palette.panel
        healthBarBG.strokeColor = .white
        healthBarBG.lineWidth = 1.5

        // Left-anchored sprite (see note in GameScene about sub-pixel shape scaling).
        healthBarFill = SKSpriteNode(color: Palette.warning, size: CGSize(width: barWidth, height: 16))
        healthBarFill.anchorPoint = CGPoint(x: 0, y: 0.5)

        super.init()

        addChild(bodyShape)

        // Glowing eyes
        for dx in [-22, 22] {
            let eye = SKShapeNode(circleOfRadius: 8)
            eye.fillColor = Palette.warning
            eye.strokeColor = .clear
            eye.glowWidth = 6
            eye.position = CGPoint(x: CGFloat(dx), y: 14)
            bodyShape.addChild(eye)
        }

        healthBarBG.position = CGPoint(x: 0, y: 86)
        addChild(healthBarBG)
        healthBarFill.position = CGPoint(x: -barWidth / 2, y: 86)
        addChild(healthBarFill)

        let pb = SKPhysicsBody(circleOfRadius: 60)
        pb.isDynamic = true
        pb.affectedByGravity = false
        pb.categoryBitMask = PhysicsCategory.boss
        pb.contactTestBitMask = PhysicsCategory.projectile
        pb.collisionBitMask = PhysicsCategory.none
        physicsBody = pb

        // Menacing sway.
        let sway = SKAction.sequence([
            .moveBy(x: 60, y: 0, duration: 1.4),
            .moveBy(x: -120, y: 0, duration: 2.8),
            .moveBy(x: 60, y: 0, duration: 1.4)
        ])
        sway.timingMode = .easeInEaseOut
        run(.repeatForever(sway))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Returns true if this hit defeated the boss.
    @discardableResult
    func takeHit(_ amount: Int = 1) -> Bool {
        health = max(0, health - amount)
        let frac = CGFloat(health) / CGFloat(maxHealth)
        healthBarFill.run(.scaleX(to: max(0.001, frac), duration: 0.12))

        let flash = SKAction.sequence([
            .run { [weak self] in self?.bodyShape.fillColor = .white },
            .wait(forDuration: 0.05),
            .run { [weak self] in
                self?.bodyShape.fillColor = SKColor(red: 0.36, green: 0.33, blue: 0.40, alpha: 1.0)
            }
        ])
        run(flash)
        return isDefeated
    }

    func playDefeat() {
        removeAllActions()
        let fall = SKAction.group([
            .rotate(byAngle: .pi, duration: 0.8),
            .moveBy(x: 0, y: -40, duration: 0.8),
            .fadeOut(withDuration: 0.8)
        ])
        run(fall)
    }

    private static func bodyPath() -> CGPath {
        let pts: [CGPoint] = [
            CGPoint(x: -60, y: -40), CGPoint(x: -64, y: 20), CGPoint(x: -40, y: 52),
            CGPoint(x: 0, y: 64), CGPoint(x: 40, y: 52), CGPoint(x: 64, y: 20),
            CGPoint(x: 60, y: -40), CGPoint(x: 30, y: -58), CGPoint(x: -30, y: -58)
        ]
        let p = CGMutablePath()
        p.addLines(between: pts)
        p.closeSubpath()
        return p
    }
}
