//
//  Backdrop.swift
//  Duck-n-Roll
//
//  Storybook-painterly scenery shared by every scene: a deep gradient sky, a
//  soft sun with halo, drifting clouds, three layers of misty parallax mountains
//  receding into atmospheric haze, a lush gradient hill, and a gentle vignette
//  that frames the whole picture.
//

import SpriteKit
import UIKit

enum Backdrop {

    // Storybook palette
    private static let skyTop    = SKColor(red: 0.28, green: 0.43, blue: 0.78, alpha: 1)
    private static let skyMid    = SKColor(red: 0.53, green: 0.69, blue: 0.93, alpha: 1)
    private static let skyHorizon = SKColor(red: 0.97, green: 0.89, blue: 0.80, alpha: 1)

    private static let mtnFar  = SKColor(red: 0.64, green: 0.67, blue: 0.84, alpha: 1)
    private static let mtnMid  = SKColor(red: 0.46, green: 0.57, blue: 0.72, alpha: 1)
    private static let mtnNear = SKColor(red: 0.39, green: 0.55, blue: 0.55, alpha: 1)

    static func install(in scene: SKScene) {
        let size = scene.size
        let w = size.width, h = size.height

        // ---- Sky ----
        let sky = SKSpriteNode(texture: TextureFactory.verticalGradient(
            size: size,
            colors: [skyHorizon, skyMid, skyTop],   // bottom -> top
            locations: [0.0, 0.46, 1.0], key: "sky"))
        sky.position = CGPoint(x: w / 2, y: h / 2)
        sky.zPosition = Z.background
        scene.addChild(sky)

        // ---- Sun + halo ----
        let sunPos = CGPoint(x: w * 0.76, y: h * 0.82)
        let halo = SKShapeNode(circleOfRadius: 110)
        halo.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.78, alpha: 0.35)
        halo.strokeColor = .clear
        halo.glowWidth = 40
        halo.position = sunPos
        halo.zPosition = Z.background + 1
        scene.addChild(halo)
        let sun = SKShapeNode(circleOfRadius: 52)
        sun.fillColor = SKColor(red: 1.0, green: 0.97, blue: 0.84, alpha: 1)
        sun.strokeColor = .clear
        sun.glowWidth = 10
        sun.position = sunPos
        sun.zPosition = Z.background + 2
        scene.addChild(sun)
        halo.run(.repeatForever(.sequence([.scale(to: 1.08, duration: 2.2),
                                           .scale(to: 1.0, duration: 2.2)])))

        // ---- Mountains (far -> near), bases tucked behind the hill crest ----
        let crestY = h * 0.585
        addMountain(to: scene, w: w, layerHeight: h * 0.26, base: mtnFar, snow: true,
                    baseY: crestY + h * 0.02, z: Z.hill - 5, key: "far", driftDur: 0)
        addMountain(to: scene, w: w, layerHeight: h * 0.21, base: mtnMid, snow: true,
                    baseY: crestY - h * 0.01, z: Z.hill - 4, key: "mid", driftDur: 0)
        addMountain(to: scene, w: w, layerHeight: h * 0.16, base: mtnNear, snow: false,
                    baseY: crestY - h * 0.035, z: Z.hill - 3, key: "near", driftDur: 0)

        // ---- Clouds (slow drift) ----
        addCloud(to: scene, w: w, x: w * 0.22, y: h * 0.86, width: w * 0.42, z: Z.hill - 6, dur: 70)
        addCloud(to: scene, w: w, x: w * 0.70, y: h * 0.72, width: w * 0.32, z: Z.hill - 6, dur: 95)
        addCloud(to: scene, w: w, x: w * 0.45, y: h * 0.93, width: w * 0.5,  z: Z.hill - 2, dur: 55)

        // ---- Hill ----
        let hill = SKSpriteNode(texture: hillTexture(width: w, height: h * 0.72))
        hill.anchorPoint = CGPoint(x: 0.5, y: 0)
        hill.position = CGPoint(x: w / 2, y: 0)
        hill.zPosition = Z.hill
        scene.addChild(hill)

        // ---- Vignette (frames the scenery) ----
        let vignette = SKSpriteNode(texture: vignetteTexture(size: size))
        vignette.position = CGPoint(x: w / 2, y: h / 2)
        vignette.zPosition = Z.hill + 1
        vignette.alpha = 0.5
        scene.addChild(vignette)
    }

    // MARK: - Builders

    private static func addMountain(to scene: SKScene, w: CGFloat, layerHeight: CGFloat,
                                    base: SKColor, snow: Bool, baseY: CGFloat, z: CGFloat,
                                    key: String, driftDur: TimeInterval) {
        let tex = TextureFactory.mountain(width: w * 1.2, height: layerHeight,
                                          base: base, snow: snow, key: key)
        let node = SKSpriteNode(texture: tex)
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.position = CGPoint(x: w / 2, y: baseY)
        node.zPosition = z
        scene.addChild(node)
    }

    private static func addCloud(to scene: SKScene, w: CGFloat, x: CGFloat, y: CGFloat,
                                 width: CGFloat, z: CGFloat, dur: TimeInterval) {
        let cloud = SKSpriteNode(texture: TextureFactory.cloud(width: width))
        cloud.position = CGPoint(x: x, y: y)
        cloud.zPosition = z
        cloud.alpha = 0.95
        scene.addChild(cloud)
        // drift left, wrap around
        let travel = w + width
        let toLeft = SKAction.moveBy(x: -travel, y: 0, duration: dur * Double(travel / w))
        let reset = SKAction.moveBy(x: travel, y: 0, duration: 0)
        cloud.run(.repeatForever(.sequence([toLeft, reset])))
    }

    // MARK: - Textures

    private static func hillTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { c in
            let ctx = c.cgContext
            let w = size.width, h = size.height
            // dome path (y-down): big ellipse whose top arc sits near the texture top
            let dome = CGPath(ellipseIn: CGRect(x: -w * 0.32, y: h * 0.06,
                                                width: w * 1.64, height: h * 2.6), transform: nil)
            ctx.saveGState(); ctx.addPath(dome); ctx.clip()
            let cgcs = CGColorSpaceCreateDeviceRGB()
            let top = SKColor(red: 0.40, green: 0.69, blue: 0.34, alpha: 1)
            let bot = SKColor(red: 0.24, green: 0.50, blue: 0.24, alpha: 1)
            let grad = CGGradient(colorsSpace: cgcs, colors: [top.cgColor, bot.cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: h * 0.06),
                                   end: CGPoint(x: 0, y: h), options: [])
            // soft perspective bands
            for i in 0..<6 {
                let f = CGFloat(i) / 6
                ctx.setFillColor(SKColor(white: 1, alpha: 0.06).cgColor)
                let bw = w * (1.1 - 0.12 * f)
                let by = h * (0.18 + 0.14 * CGFloat(i))
                ctx.fillEllipse(in: CGRect(x: w / 2 - bw / 2, y: by, width: bw, height: 26))
            }
            ctx.restoreGState()
            // crest highlight along the top arc
            ctx.addPath(dome)
            ctx.setStrokeColor(SKColor(red: 0.62, green: 0.85, blue: 0.5, alpha: 0.8).cgColor)
            ctx.setLineWidth(6); ctx.strokePath()
        }
        return SKTexture(image: image)
    }

    private static func vignetteTexture(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { c in
            let ctx = c.cgContext
            let cgcs = CGColorSpaceCreateDeviceRGB()
            let grad = CGGradient(colorsSpace: cgcs,
                                  colors: [SKColor.clear.cgColor,
                                           SKColor.clear.cgColor,
                                           SKColor(red: 0.10, green: 0.10, blue: 0.22, alpha: 0.55).cgColor] as CFArray,
                                  locations: [0, 0.62, 1])!
            let c0 = CGPoint(x: size.width / 2, y: size.height / 2)
            ctx.drawRadialGradient(grad, startCenter: c0, startRadius: 0, endCenter: c0,
                                   endRadius: max(size.width, size.height) * 0.72, options: [.drawsAfterEndLocation])
        }
        return SKTexture(image: image)
    }
}
