//
//  CaveNode.swift
//  Duck-n-Roll
//
//  An alternative home base: a dark cave mouth set into the foot of the mountain
//  (instead of the cottage). Same Shelter interface as HutNode so the scene can
//  use either interchangeably.
//

import SpriteKit

/// Anything the duck can shelter in during an earthquake.
protocol Shelter: AnyObject {
    var doorOffset: CGPoint { get }   // local centre of the entrance
    var safeRadius: CGFloat { get }
    func setWarning(active: Bool)
}

extension HutNode: Shelter {}

final class CaveNode: SKNode, Shelter {

    let doorOffset = CGPoint(x: 0, y: -10)
    let safeRadius: CGFloat = 104

    private let glow: SKShapeNode

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
        let rock = SKColor(red: 0.42, green: 0.40, blue: 0.44, alpha: 1)
        let rockDark = SKColor(red: 0.27, green: 0.25, blue: 0.30, alpha: 1)

        // Ground shadow
        let shadow = SKSpriteNode(texture: TextureFactory.softShadow(diameter: 200))
        shadow.position = CGPoint(x: 0, y: -40); shadow.yScale = 0.45
        shadow.alpha = 0.5; shadow.zPosition = -2
        addChild(shadow)

        // Rocky mound the cave is carved into (overlapping boulders for an organic edge)
        let moundOffsets: [(CGFloat, CGFloat, CGFloat)] = [
            (0, 8, 86), (-58, -6, 40), (58, -6, 42), (-40, 30, 34), (40, 30, 34), (0, 48, 40)
        ]
        for (x, y, r) in moundOffsets {
            let b = SKShapeNode(circleOfRadius: r)
            b.fillColor = rock
            b.strokeColor = rockDark
            b.lineWidth = 2
            b.position = CGPoint(x: x, y: y)
            b.zPosition = 0.1
            addChild(b)
        }
        // top highlight band
        let hi = SKShapeNode(ellipseOf: CGSize(width: 150, height: 30))
        hi.fillColor = rock.lighter(0.12).withAlphaComponent(0.6)
        hi.strokeColor = .clear
        hi.position = CGPoint(x: 0, y: 56); hi.zPosition = 0.2
        addChild(hi)

        // Cave mouth — black arch (radial dark) set into the mound
        let mouth = SKShapeNode(path: mouthPath())
        mouth.fillColor = SKColor(red: 0.04, green: 0.03, blue: 0.06, alpha: 1)
        mouth.strokeColor = rockDark
        mouth.lineWidth = 3
        mouth.position = CGPoint(x: 0, y: -2)
        mouth.zPosition = 0.5
        addChild(mouth)
        // inner depth gradient
        let depth = SKSpriteNode(texture: TextureFactory.softShadow(diameter: 110))
        depth.color = .black
        depth.position = CGPoint(x: 0, y: 6)
        depth.zPosition = 0.55
        depth.alpha = 0.9
        addChild(depth)

        // Warm flicker deep inside (so it reads as a cosy shelter, not a trap)
        let fire = SKShapeNode(circleOfRadius: 9)
        fire.fillColor = SKColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.9)
        fire.strokeColor = .clear
        fire.glowWidth = 10
        fire.position = CGPoint(x: 0, y: -16)
        fire.zPosition = 0.6
        addChild(fire)
        fire.run(.repeatForever(.sequence([
            .group([.scale(to: 1.25, duration: 0.4), .fadeAlpha(to: 0.7, duration: 0.4)]),
            .group([.scale(to: 1.0, duration: 0.35), .fadeAlpha(to: 0.95, duration: 0.35)])])))

        // Stalactites hanging from the top of the mouth
        for dx in [CGFloat(-26), -8, 10, 26] {
            let s = SKShapeNode(path: stalactitePath(h: CGFloat.random(in: 12...20)))
            s.fillColor = rockDark
            s.strokeColor = .clear
            s.position = CGPoint(x: dx, y: 34)
            s.zPosition = 0.7
            addChild(s)
        }

        // A few grass tufts on top
        for dx in [CGFloat(-50), 50, 0] {
            let g = SKShapeNode(path: grassPath())
            g.fillColor = SKColor(red: 0.36, green: 0.66, blue: 0.32, alpha: 1)
            g.strokeColor = .clear
            g.position = CGPoint(x: dx, y: 70)
            g.zPosition = 0.3
            addChild(g)
        }
    }

    private func mouthPath() -> CGPath {
        // arched opening, flat-ish bottom
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -42, y: -44))
        p.addLine(to: CGPoint(x: -42, y: 4))
        p.addQuadCurve(to: CGPoint(x: 42, y: 4), control: CGPoint(x: 0, y: 60))
        p.addLine(to: CGPoint(x: 42, y: -44))
        p.closeSubpath()
        return p
    }
    private func stalactitePath(h: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -5, y: 0)); p.addLine(to: CGPoint(x: 0, y: -h))
        p.addLine(to: CGPoint(x: 5, y: 0)); p.closeSubpath(); return p
    }
    private func grassPath() -> CGPath {
        let p = CGMutablePath()
        for dx in [CGFloat(-8), 0, 8] {
            p.move(to: CGPoint(x: dx, y: 0)); p.addLine(to: CGPoint(x: dx - 2, y: 14))
            p.move(to: CGPoint(x: dx, y: 0)); p.addLine(to: CGPoint(x: dx + 2, y: 14))
        }
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
