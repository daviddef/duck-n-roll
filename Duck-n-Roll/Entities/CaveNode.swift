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
        let rock   = SKColor(white: 0.46, alpha: 1)   // jagged rock body
        let throat = SKColor(white: 0.29, alpha: 1)   // arch rim / inner wall
        let hole   = SKColor(white: 0.02, alpha: 1)   // dark cave interior

        // Jagged rock silhouette
        let mound = SKShapeNode(path: rockPath())
        mound.fillColor = rock
        mound.strokeColor = .clear
        mound.zPosition = 0.1
        addChild(mound)

        // Arched opening: a thin darker throat ring, then a big black interior.
        let outer = SKShapeNode(path: archPath(halfW: 54, bottom: -48, top: 56))
        outer.fillColor = throat
        outer.strokeColor = .clear
        outer.zPosition = 0.3
        addChild(outer)

        let inner = SKShapeNode(path: archPath(halfW: 46, bottom: -48, top: 49))
        inner.fillColor = hole
        inner.strokeColor = .clear
        inner.zPosition = 0.4
        addChild(inner)
    }

    /// A flat-bottomed dome (vertical sides + semicircular top).
    private func archPath(halfW: CGFloat, bottom: CGFloat, top: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -halfW, y: bottom))
        p.addLine(to: CGPoint(x: -halfW, y: top - halfW))
        p.addArc(center: CGPoint(x: 0, y: top - halfW), radius: halfW,
                 startAngle: .pi, endAngle: 0, clockwise: false)
        p.addLine(to: CGPoint(x: halfW, y: bottom))
        p.closeSubpath()
        return p
    }

    private func rockPath() -> CGPath {
        let pts: [CGPoint] = [
            CGPoint(x: -78, y: -48), CGPoint(x: -82, y: 6),  CGPoint(x: -66, y: 22),
            CGPoint(x: -74, y: 46),  CGPoint(x: -52, y: 54), CGPoint(x: -46, y: 78),
            CGPoint(x: -22, y: 64),  CGPoint(x: -6, y: 86),  CGPoint(x: 14, y: 70),
            CGPoint(x: 34, y: 82),   CGPoint(x: 42, y: 58),  CGPoint(x: 62, y: 60),
            CGPoint(x: 56, y: 34),   CGPoint(x: 76, y: 24),  CGPoint(x: 64, y: 2),
            CGPoint(x: 78, y: -20),  CGPoint(x: 70, y: -48)
        ]
        let p = CGMutablePath()
        p.addLines(between: pts)
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
