//
//  PlayerNode.swift
//  MateoDuckGame
//
//  The hero, drawn with shaded gradient spheres (via TextureFactory) for a soft
//  3D look plus a ground shadow, cheek blush, blink and a wing flap. Restyles
//  itself on every evolution. Supports a squash-and-stretch hop (with brief dodge
//  invulnerability) and a hit flash.
//

import SpriteKit

final class PlayerNode: SKNode {

    private(set) var stage: EvolutionStage = EvolutionStage.all[0]

    /// Visuals live in here so they can bob / squash without moving the shadow.
    private let bodyContainer = SKNode()
    private let groundShadow = SKSpriteNode(texture: TextureFactory.softShadow(diameter: 120))
    private var eyeNode: SKShapeNode?
    private var wingNode: SKNode?

    private(set) var isJumping = false
    private(set) var isInvulnerable = false

    private let baseRadius: CGFloat = 30

    override init() {
        super.init()
        groundShadow.zPosition = -1
        groundShadow.alpha = 0.55
        addChild(groundShadow)
        addChild(bodyContainer)
        configure(for: EvolutionStage.all[0])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Appearance

    func configure(for stage: EvolutionStage) {
        self.stage = stage
        bodyContainer.removeAllChildren()
        bodyContainer.setScale(stage.scale)
        groundShadow.setScale(stage.scale)
        groundShadow.position = CGPoint(x: 0, y: -baseRadius * 0.95)
        buildBody()
        rebuildPhysics()
    }

    private func buildBody() {
        let color = stage.bodyColor
        let d = baseRadius * 2

        // Body (shaded sphere)
        let body = SKSpriteNode(texture: TextureFactory.glossySphere(
            diameter: d, base: color, key: "duckBody\(stage.index)"))
        bodyContainer.addChild(body)

        // Belly highlight
        let belly = SKShapeNode(ellipseOf: CGSize(width: d * 0.78, height: d * 0.6))
        belly.fillColor = color.lighter(0.28).withAlphaComponent(0.85)
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -baseRadius * 0.28)
        belly.zPosition = 0.2
        bodyContainer.addChild(belly)

        // Wing (animatable flap)
        let wing = SKShapeNode(ellipseOf: CGSize(width: baseRadius * 0.95, height: baseRadius * 0.62))
        wing.fillColor = color.darker(0.06)
        wing.strokeColor = color.darker(0.2)
        wing.lineWidth = 2
        wing.position = CGPoint(x: -baseRadius * 0.42, y: -baseRadius * 0.05)
        wing.zPosition = 0.6
        let wingPivot = SKNode()
        wingPivot.position = wing.position
        wing.position = .zero
        wingPivot.addChild(wing)
        wingPivot.zRotation = 0
        bodyContainer.addChild(wingPivot)
        wingNode = wingPivot
        wingPivot.run(.repeatForever(.sequence([
            .rotate(toAngle: -0.22, duration: 0.5, shortestUnitArc: true),
            .rotate(toAngle: 0.05, duration: 0.5, shortestUnitArc: true)
        ])))

        // Head (shaded sphere)
        let headR = baseRadius * 0.64
        let head = SKSpriteNode(texture: TextureFactory.glossySphere(
            diameter: headR * 2, base: color, key: "duckHead\(stage.index)"))
        head.position = CGPoint(x: baseRadius * 0.52, y: baseRadius * 0.72)
        head.zPosition = 1.0
        bodyContainer.addChild(head)

        // Cheek blush
        let blush = SKShapeNode(circleOfRadius: baseRadius * 0.16)
        blush.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.45)
        blush.strokeColor = .clear
        blush.position = CGPoint(x: head.position.x - 2, y: head.position.y - baseRadius * 0.18)
        blush.zPosition = 1.1
        bodyContainer.addChild(blush)

        // Beak
        let beak = SKShapeNode(path: trianglePath(width: 22, height: 14))
        beak.fillColor = Palette.duckBeak
        beak.strokeColor = Palette.duckBeak.darker()
        beak.lineWidth = 1.5
        beak.position = CGPoint(x: head.position.x + headR + 6, y: head.position.y - 2)
        beak.zRotation = -.pi / 2
        beak.zPosition = 1.2
        bodyContainer.addChild(beak)

        // Eye (with highlight) — blinks
        let eye = SKShapeNode(circleOfRadius: 4.2)
        eye.fillColor = Palette.ink
        eye.strokeColor = .clear
        eye.position = CGPoint(x: head.position.x + headR * 0.42, y: head.position.y + headR * 0.34)
        eye.zPosition = 1.3
        let glint = SKShapeNode(circleOfRadius: 1.5)
        glint.fillColor = .white
        glint.strokeColor = .clear
        glint.position = CGPoint(x: 1.4, y: 1.4)
        eye.addChild(glint)
        bodyContainer.addChild(eye)
        eyeNode = eye
        let blink = SKAction.sequence([
            .wait(forDuration: 2.4),
            .scaleY(to: 0.1, duration: 0.06),
            .scaleY(to: 1.0, duration: 0.06)
        ])
        eye.run(.repeatForever(blink))

        // Crest plume (mid evolution onward)
        if stage.hasCrest {
            let plume = SKShapeNode(path: trianglePath(width: 12, height: 22))
            plume.fillColor = color.darker()
            plume.strokeColor = color.darker(0.3)
            plume.lineWidth = 1
            plume.position = CGPoint(x: head.position.x - 4, y: head.position.y + headR + 4)
            plume.zPosition = 0.9
            bodyContainer.addChild(plume)
        }
        // Wing tips (late evolution)
        if stage.hasWingTips {
            let tip = SKShapeNode(path: trianglePath(width: 16, height: 30))
            tip.fillColor = color.lighter(0.2)
            tip.strokeColor = color.darker()
            tip.lineWidth = 1.5
            tip.position = CGPoint(x: -baseRadius * 0.8, y: -baseRadius * 0.1)
            tip.zRotation = .pi * 0.9
            tip.zPosition = 0.5
            bodyContainer.addChild(tip)
        }
    }

    private func rebuildPhysics() {
        let r = baseRadius * stage.scale * 0.85
        let pb = SKPhysicsBody(circleOfRadius: r)
        pb.isDynamic = true
        pb.affectedByGravity = false
        pb.allowsRotation = false
        pb.categoryBitMask = PhysicsCategory.player
        pb.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.boss
        pb.collisionBitMask = PhysicsCategory.none
        physicsBody = pb
    }

    // MARK: - Actions

    func startIdleBob() {
        bodyContainer.removeAction(forKey: "bob")
        let up = SKAction.moveBy(x: 0, y: 5, duration: 0.65)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        bodyContainer.run(.repeatForever(.sequence([up, down])), withKey: "bob")
    }

    /// Squash-and-stretch hop. `power` scales hang time and height.
    func jump(power: CGFloat, completion: (() -> Void)? = nil) {
        guard !isJumping else { return }
        isJumping = true
        bodyContainer.removeAction(forKey: "bob")

        let s = stage.scale
        let height: CGFloat = 78 * power
        let dur = 0.30 * Double(power)

        let anticipate = SKAction.group([
            .scaleX(to: s * 1.12, duration: 0.08),
            .scaleY(to: s * 0.86, duration: 0.08)
        ])
        let up = SKAction.moveBy(x: 0, y: height, duration: dur); up.timingMode = .easeOut
        let stretch = SKAction.group([.scaleX(to: s * 0.9, duration: dur), .scaleY(to: s * 1.16, duration: dur)])
        let down = SKAction.moveBy(x: 0, y: -height, duration: dur); down.timingMode = .easeIn
        let squash = SKAction.group([.scaleX(to: s * 1.16, duration: 0.1), .scaleY(to: s * 0.84, duration: 0.1)])
        let settle = SKAction.scale(to: s, duration: 0.1)

        // Shadow shrinks while airborne for a sense of height.
        groundShadow.run(.sequence([
            .scale(to: s * 0.6, duration: dur),
            .scale(to: s, duration: dur)
        ]))

        bodyContainer.run(.sequence([
            anticipate,
            .group([up, stretch]),
            .group([down]),
            squash, settle
        ])) { [weak self] in
            self?.isJumping = false
            self?.startIdleBob()
            completion?()
        }
    }

    func flashDamage() {
        isInvulnerable = true
        let blink = SKAction.sequence([
            .fadeAlpha(to: 0.25, duration: 0.08),
            .fadeAlpha(to: 1.0, duration: 0.08)
        ])
        run(.sequence([.repeat(blink, count: 6),
                       .run { [weak self] in self?.isInvulnerable = false }]),
            withKey: "invuln")
    }

    func celebrate() {
        let s = stage.scale
        let spin = SKAction.sequence([
            .group([.scaleX(to: s * 1.2, duration: 0.15), .scaleY(to: s * 1.28, duration: 0.15)]),
            .scale(to: s, duration: 0.15)
        ])
        bodyContainer.run(.repeat(spin, count: 3))
    }

    // MARK: - Helpers

    private func trianglePath(width: CGFloat, height: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: height / 2))
        p.addLine(to: CGPoint(x: -width / 2, y: -height / 2))
        p.addLine(to: CGPoint(x: width / 2, y: -height / 2))
        p.closeSubpath()
        return p
    }
}
