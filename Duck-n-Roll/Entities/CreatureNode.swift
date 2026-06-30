//
//  CreatureNode.swift
//  Duck-n-Roll
//
//  Critters that get in your way up the mountain — a spiky caterpillar, a poison
//  frog and a snake. They patrol side-to-side and are **lethal on contact** (you
//  can't touch them), so you have to weave around them to reach the treats.
//

import SpriteKit

enum CreatureKind: CaseIterable {
    case caterpillar, frog, snake
}

final class CreatureNode: SKNode {

    let kind: CreatureKind
    var patrolDir: CGFloat
    var crawlSpeed: CGFloat
    var life: TimeInterval
    var scored = false

    /// Contact radius with the player.
    let hitRadius: CGFloat = 30

    init(kind: CreatureKind, speed: CGFloat, lifetime: TimeInterval = 7) {
        self.kind = kind
        self.crawlSpeed = speed
        self.life = lifetime
        self.patrolDir = Bool.random() ? 1 : -1
        super.init()

        // soft ground shadow
        let shadow = SKSpriteNode(texture: TextureFactory.softShadow(diameter: 90))
        shadow.position = CGPoint(x: 0, y: -22)
        shadow.yScale = 0.4
        shadow.alpha = 0.5
        shadow.zPosition = -1
        addChild(shadow)

        switch kind {
        case .caterpillar: buildCaterpillar()
        case .frog:        buildFrog()
        case .snake:       buildSnake()
        }

        // "danger" pulse so kids read it as something to avoid
        run(.repeatForever(.sequence([.scale(to: 1.06, duration: 0.4),
                                      .scale(to: 1.0, duration: 0.4)])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Art

    private func buildCaterpillar() {
        let green = SKColor(red: 0.55, green: 0.80, blue: 0.25, alpha: 1)
        let dark = green.darker(0.25)
        let segs = 4
        for i in 0..<segs {
            let x = CGFloat(i) * 20 - CGFloat(segs - 1) * 10
            let r: CGFloat = i == segs - 1 ? 16 : 13   // head a bit bigger
            let seg = SKShapeNode(circleOfRadius: r)
            seg.fillColor = i.isMultiple(of: 2) ? green : green.lighter(0.08)
            seg.strokeColor = dark
            seg.lineWidth = 2
            seg.position = CGPoint(x: x, y: 0)
            addChild(seg)
            // spikes on top
            for sgn in [CGFloat(-0.4), 0.4] {
                let spike = SKShapeNode(path: trianglePath(w: 7, h: 12))
                spike.fillColor = dark
                spike.strokeColor = .clear
                spike.position = CGPoint(x: x + sgn * 6, y: r * 0.7)
                addChild(spike)
            }
            if i == segs - 1 {   // head: eyes + antennae
                for sgn in [CGFloat(-1), 1] {
                    let eye = SKShapeNode(circleOfRadius: 3.5)
                    eye.fillColor = .white; eye.strokeColor = Palette.ink; eye.lineWidth = 1
                    eye.position = CGPoint(x: x + sgn * 5, y: 4)
                    addChild(eye)
                    let pupil = SKShapeNode(circleOfRadius: 1.6)
                    pupil.fillColor = Palette.ink; pupil.strokeColor = .clear
                    pupil.position = CGPoint(x: x + sgn * 5, y: 4); addChild(pupil)
                }
            }
        }
    }

    private func buildFrog() {
        let body = SKColor(red: 0.40, green: 0.78, blue: 0.45, alpha: 1)
        let blob = SKShapeNode(ellipseOf: CGSize(width: 52, height: 40))
        blob.fillColor = body; blob.strokeColor = body.darker(0.25); blob.lineWidth = 2.5
        addChild(blob)
        // poison spots
        for p in [CGPoint(x: -12, y: 4), CGPoint(x: 10, y: -6), CGPoint(x: 0, y: 8)] {
            let spot = SKShapeNode(circleOfRadius: 5)
            spot.fillColor = SKColor(red: 0.55, green: 0.25, blue: 0.7, alpha: 1)
            spot.strokeColor = .clear; spot.position = p; addChild(spot)
        }
        // eyes on top
        for sgn in [CGFloat(-1), 1] {
            let bump = SKShapeNode(circleOfRadius: 9)
            bump.fillColor = body; bump.strokeColor = body.darker(0.25); bump.lineWidth = 2
            bump.position = CGPoint(x: sgn * 13, y: 18); addChild(bump)
            let eye = SKShapeNode(circleOfRadius: 5)
            eye.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.1, alpha: 1)
            eye.strokeColor = Palette.ink; eye.lineWidth = 1
            eye.position = CGPoint(x: sgn * 13, y: 20); addChild(eye)
            let slit = SKShapeNode(rectOf: CGSize(width: 1.6, height: 7))
            slit.fillColor = Palette.ink; slit.strokeColor = .clear
            slit.position = CGPoint(x: sgn * 13, y: 20); addChild(slit)
        }
        // mouth
        let mouth = SKShapeNode(path: archPath(w: 30, h: 6))
        mouth.strokeColor = body.darker(0.4); mouth.lineWidth = 2.5; mouth.fillColor = .clear
        mouth.position = CGPoint(x: 0, y: -8); addChild(mouth)
    }

    private func buildSnake() {
        let green = SKColor(red: 0.35, green: 0.70, blue: 0.40, alpha: 1)
        let dark = green.darker(0.25)
        let count = 6
        for i in 0..<count {
            let x = CGFloat(i) * 15 - CGFloat(count - 1) * 7.5
            let y = sin(CGFloat(i) * 0.9) * 8
            let r: CGFloat = 11 - CGFloat(i) * 0.6
            let seg = SKShapeNode(circleOfRadius: max(5, r))
            seg.fillColor = i.isMultiple(of: 2) ? green : green.lighter(0.1)
            seg.strokeColor = dark; seg.lineWidth = 2
            seg.position = CGPoint(x: x, y: y); addChild(seg)
            if i == 0 {   // head
                for sgn in [CGFloat(-1), 1] {
                    let eye = SKShapeNode(circleOfRadius: 2.6)
                    eye.fillColor = .white; eye.strokeColor = Palette.ink; eye.lineWidth = 0.8
                    eye.position = CGPoint(x: x - 4, y: y + sgn * 4); addChild(eye)
                }
                let tongue = SKShapeNode(path: forkPath())
                tongue.strokeColor = Palette.ball; tongue.lineWidth = 1.5; tongue.fillColor = .clear
                tongue.position = CGPoint(x: x - 11, y: y); addChild(tongue)
            }
        }
    }

    // MARK: - Paths

    private func trianglePath(w: CGFloat, h: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: h / 2))
        p.addLine(to: CGPoint(x: -w / 2, y: -h / 2))
        p.addLine(to: CGPoint(x: w / 2, y: -h / 2))
        p.closeSubpath(); return p
    }
    private func archPath(w: CGFloat, h: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -w / 2, y: 0))
        p.addQuadCurve(to: CGPoint(x: w / 2, y: 0), control: CGPoint(x: 0, y: -h * 2))
        return p
    }
    private func forkPath() -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: -7, y: 0))
        p.move(to: CGPoint(x: -7, y: 0)); p.addLine(to: CGPoint(x: -11, y: 3))
        p.move(to: CGPoint(x: -7, y: 0)); p.addLine(to: CGPoint(x: -11, y: -3))
        return p
    }
}
