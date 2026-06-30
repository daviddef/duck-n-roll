//
//  HutNode.swift
//  MateoDuckGame
//
//  The cosy home base / earthquake shelter — a warm timber cottage with shaded
//  plank walls, a shingled terracotta roof, a glowing arched doorway the duck can
//  actually run into, a lit window and a smoking chimney. Exposes a door offset
//  and safe radius so the scene can do a distance-based shelter check.
//

import SpriteKit

final class HutNode: SKNode {

    /// Local offset of the doorway centre (where the duck enters).
    let doorOffset = CGPoint(x: 0, y: -18)
    /// How close (in points) the duck must be to the door to be sheltered.
    let safeRadius: CGFloat = 104

    private let glow: SKShapeNode

    // Warm cottage palette
    private let wood      = SKColor(red: 0.78, green: 0.56, blue: 0.36, alpha: 1)
    private let woodDark  = SKColor(red: 0.55, green: 0.37, blue: 0.22, alpha: 1)
    private let roofColor = SKColor(red: 0.86, green: 0.43, blue: 0.31, alpha: 1)
    private let cream     = SKColor(red: 0.97, green: 0.92, blue: 0.80, alpha: 1)
    private let warmGlow  = SKColor(red: 1.0, green: 0.83, blue: 0.46, alpha: 1)

    override init() {
        glow = SKShapeNode(circleOfRadius: 96)
        glow.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 0.16)
        glow.strokeColor = SKColor(red: 1.0, green: 0.82, blue: 0.25, alpha: 1)
        glow.lineWidth = 5
        glow.glowWidth = 10
        glow.alpha = 0
        glow.zPosition = -3
        super.init()
        addChild(glow)
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        // Ground shadow
        let shadow = SKSpriteNode(texture: TextureFactory.softShadow(diameter: 190))
        shadow.position = CGPoint(x: 0, y: -44)
        shadow.yScale = 0.45
        shadow.alpha = 0.5
        shadow.zPosition = -2
        addChild(shadow)

        // --- Walls (shaded planks) ---
        let wallSize = CGSize(width: 124, height: 86)
        let wall = SKSpriteNode(texture: TextureFactory.verticalGradient(
            size: wallSize, colors: [woodDark, wood.lighter(0.06)], locations: [0, 1], key: "hutWall2"),
                                size: wallSize)
        wall.position = CGPoint(x: 0, y: 0)
        addChild(wall)
        // plank seams
        for i in 1...3 {
            let seam = SKShapeNode(rectOf: CGSize(width: 124, height: 1.5))
            seam.fillColor = woodDark.withAlphaComponent(0.5)
            seam.strokeColor = .clear
            seam.position = CGPoint(x: 0, y: 43 - CGFloat(i) * 21)
            addChild(seam)
        }
        // corner posts + base trim
        for sx in [CGFloat(-1), 1] {
            let post = SKShapeNode(rectOf: CGSize(width: 8, height: 86))
            post.fillColor = woodDark
            post.strokeColor = .clear
            post.position = CGPoint(x: sx * 58, y: 0)
            addChild(post)
        }
        let baseTrim = SKShapeNode(rectOf: CGSize(width: 130, height: 10))
        baseTrim.fillColor = woodDark.darker(0.1); baseTrim.strokeColor = .clear
        baseTrim.position = CGPoint(x: 0, y: -43)
        addChild(baseTrim)

        // --- Doorway (arched, glowing interior) ---
        let interior = SKShapeNode(rect: CGRect(x: -22, y: -43, width: 44, height: 60), cornerRadius: 22)
        interior.fillColor = warmGlow
        interior.strokeColor = .clear
        interior.glowWidth = 6
        interior.position = doorOffset
        interior.zPosition = 0.5
        addChild(interior)
        interior.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.78, duration: 1.3), .fadeAlpha(to: 1.0, duration: 1.3)])))
        // door frame
        let frame = SKShapeNode(rect: CGRect(x: -24, y: -43, width: 48, height: 62), cornerRadius: 24)
        frame.fillColor = .clear
        frame.strokeColor = cream
        frame.lineWidth = 4
        frame.position = doorOffset
        frame.zPosition = 0.6
        addChild(frame)
        // open door leaf to one side
        let leaf = SKShapeNode(rect: CGRect(x: -22, y: -43, width: 20, height: 58), cornerRadius: 8)
        leaf.fillColor = woodDark
        leaf.strokeColor = woodDark.darker()
        leaf.lineWidth = 2
        leaf.position = CGPoint(x: doorOffset.x - 14, y: doorOffset.y)
        leaf.zRotation = 0.18
        leaf.zPosition = 0.7
        addChild(leaf)

        // --- Window (lit) ---
        let win = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 4)
        win.fillColor = warmGlow
        win.strokeColor = cream
        win.lineWidth = 4
        win.glowWidth = 4
        win.position = CGPoint(x: 38, y: 8)
        win.zPosition = 0.5
        addChild(win)
        let fv = SKShapeNode(rectOf: CGSize(width: 3, height: 28)); fv.fillColor = cream; fv.strokeColor = .clear
        fv.position = win.position; fv.zPosition = 0.55; addChild(fv)
        let fh = SKShapeNode(rectOf: CGSize(width: 28, height: 3)); fh.fillColor = cream; fh.strokeColor = .clear
        fh.position = win.position; fh.zPosition = 0.55; addChild(fh)
        win.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.82, duration: 1.5), .fadeAlpha(to: 1.0, duration: 1.5)])))

        // --- Roof (shingled, overhang) ---
        let roof = SKShapeNode(path: roofPath())
        roof.fillColor = roofColor
        roof.strokeColor = roofColor.darker()
        roof.lineWidth = 3
        roof.position = CGPoint(x: 0, y: 43)
        roof.zPosition = 0.8
        addChild(roof)
        // shingle rows
        for row in 0..<3 {
            let y = CGFloat(row) * 13 + 6
            let halfW = 78 * (1 - y / 52)
            let line = SKShapeNode(rectOf: CGSize(width: max(0, halfW * 2), height: 2))
            line.fillColor = roofColor.darker(0.18); line.strokeColor = .clear
            line.position = CGPoint(x: 0, y: 43 + y)
            line.zPosition = 0.85
            addChild(line)
        }
        // ridge cap
        let ridge = SKShapeNode(circleOfRadius: 6)
        ridge.fillColor = cream; ridge.strokeColor = .clear
        ridge.position = CGPoint(x: 0, y: 43 + 50)
        ridge.zPosition = 0.9
        addChild(ridge)

        // --- Chimney + smoke ---
        let chimney = SKShapeNode(rect: CGRect(x: 34, y: 58, width: 16, height: 30), cornerRadius: 2)
        chimney.fillColor = roofColor.darker(0.1)
        chimney.strokeColor = roofColor.darker(0.35)
        chimney.lineWidth = 2
        chimney.zPosition = 0.7
        addChild(chimney)
        emitSmoke(from: CGPoint(x: 42, y: 90))

        // --- Hanging "HOME" sign ---
        let sign = SKShapeNode(rectOf: CGSize(width: 44, height: 18), cornerRadius: 4)
        sign.fillColor = cream
        sign.strokeColor = woodDark
        sign.lineWidth = 2
        sign.position = CGPoint(x: 0, y: 30)
        sign.zPosition = 0.9
        addChild(sign)
        let signText = SKLabelNode(fontNamed: FontName.heavy)
        signText.text = "HOME"; signText.fontSize = 11; signText.fontColor = woodDark
        signText.verticalAlignmentMode = .center; signText.position = sign.position
        signText.zPosition = 0.95
        addChild(signText)
        sign.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.04, duration: 1.1, shortestUnitArc: true),
            .rotate(toAngle: -0.04, duration: 1.1, shortestUnitArc: true)])))
    }

    private func emitSmoke(from p: CGPoint) {
        let spawn = SKAction.run { [weak self] in
            guard let self else { return }
            let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...7))
            puff.fillColor = SKColor(white: 0.88, alpha: 0.55)
            puff.strokeColor = .clear
            puff.position = p
            puff.zPosition = 0.6
            self.addChild(puff)
            puff.run(.sequence([
                .group([.moveBy(x: CGFloat.random(in: -10...16), y: 50, duration: 2.2),
                        .scale(to: 2.4, duration: 2.2), .fadeOut(withDuration: 2.2)]),
                .removeFromParent()]))
        }
        run(.repeatForever(.sequence([spawn, .wait(forDuration: 0.8)])), withKey: "smoke")
    }

    private func roofPath() -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -78, y: 0))
        p.addLine(to: CGPoint(x: 0, y: 52))
        p.addLine(to: CGPoint(x: 78, y: 0))
        p.addLine(to: CGPoint(x: 66, y: -10))
        p.addLine(to: CGPoint(x: 0, y: 38))
        p.addLine(to: CGPoint(x: -66, y: -10))
        p.closeSubpath()
        return p
    }

    func setWarning(active: Bool) {
        glow.removeAllActions()
        if active {
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.95, duration: 0.25), .fadeAlpha(to: 0.4, duration: 0.25)])))
        } else {
            glow.run(.fadeAlpha(to: 0, duration: 0.2))
        }
    }
}
