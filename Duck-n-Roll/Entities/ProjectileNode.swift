//
//  ProjectileNode.swift
//  Duck-n-Roll
//
//  A glowing energy bolt fired up the hill at obstacles (unlocked from level 3).
//  Higher evolution forms tint it to match their plumage.
//

import SpriteKit

final class ProjectileNode: SKNode {

    init(tint: SKColor = Palette.projectile) {
        super.init()

        // soft outer halo
        let halo = SKShapeNode(circleOfRadius: 13)
        halo.fillColor = tint.withAlphaComponent(0.35)
        halo.strokeColor = .clear
        halo.glowWidth = 6
        addChild(halo)

        // trailing streak
        let tail = SKShapeNode(path: tailPath())
        tail.fillColor = tint.withAlphaComponent(0.4)
        tail.strokeColor = .clear
        tail.zPosition = -0.1
        addChild(tail)

        // bright core
        let core = SKShapeNode(ellipseOf: CGSize(width: 13, height: 24))
        core.fillColor = tint.lighter(0.25)
        core.strokeColor = .white
        core.lineWidth = 2
        core.glowWidth = 5
        addChild(core)
        core.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.12), .scale(to: 1.0, duration: 0.12)])))

        let pb = SKPhysicsBody(circleOfRadius: 9)
        pb.isDynamic = true
        pb.affectedByGravity = false
        pb.categoryBitMask = PhysicsCategory.projectile
        pb.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.boss
        pb.collisionBitMask = PhysicsCategory.none
        physicsBody = pb
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func tailPath() -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -7, y: -6))
        p.addLine(to: CGPoint(x: 0, y: -34))
        p.addLine(to: CGPoint(x: 7, y: -6))
        p.closeSubpath()
        return p
    }
}
