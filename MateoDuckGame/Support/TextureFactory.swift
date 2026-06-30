//
//  TextureFactory.swift
//  MateoDuckGame
//
//  Procedurally renders rich, shaded sprites (gradients, gloss, soft shadows,
//  rock texture, mist) into cached SKTextures. This is what gives the game its
//  "storybook painterly" look without shipping any image assets.
//
//  Everything is drawn with Core Graphics at the device's native scale, so the
//  results stay crisp on retina screens. Textures are cached by key — each is
//  rendered at most once.
//

import SpriteKit
import UIKit

enum TextureFactory {

    private static var cache: [String: SKTexture] = [:]

    private static func cached(_ key: String, size: CGSize,
                               _ draw: @escaping (CGContext, CGSize) -> Void) -> SKTexture {
        if let t = cache[key] { return t }
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { c in draw(c.cgContext, size) }
        let tex = SKTexture(image: image)
        tex.filteringMode = .linear
        cache[key] = tex
        return tex
    }

    // MARK: - Spheres (balls + duck parts)

    /// A glossy 3D sphere: radial body gradient, darkened rim, bright specular.
    static func glossySphere(diameter: CGFloat, base: SKColor, key: String) -> SKTexture {
        let pad: CGFloat = diameter * 0.16   // room for the soft outer shadow
        let size = CGSize(width: diameter + pad * 2, height: diameter + pad * 2)
        return cached("sphere-\(key)", size: size) { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let r = diameter / 2

            // contact shadow (y-down context: +y is downward)
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: diameter * 0.05),
                          blur: diameter * 0.12, color: SKColor.black.withAlphaComponent(0.30).cgColor)
            ctx.setFillColor(base.cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.restoreGState()

            // body radial gradient: light near a top-left light source -> base -> dark rim
            let light = base.lighter(0.32)
            let dark = base.darker(0.28)
            let cgcs = CGColorSpaceCreateDeviceRGB()
            let grad = CGGradient(colorsSpace: cgcs,
                                  colors: [light.cgColor, base.cgColor, dark.cgColor] as CFArray,
                                  locations: [0, 0.55, 1])!
            ctx.saveGState()
            ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            ctx.clip()
            let hi = CGPoint(x: c.x - r * 0.35, y: c.y - r * 0.4)   // top-left light (y-down)
            ctx.drawRadialGradient(grad, startCenter: hi, startRadius: 0,
                                   endCenter: c, endRadius: r * 1.15, options: [.drawsAfterEndLocation])
            ctx.restoreGState()

            // specular highlight
            ctx.setFillColor(SKColor.white.withAlphaComponent(0.55).cgColor)
            let sr = r * 0.26
            ctx.fillEllipse(in: CGRect(x: hi.x - sr, y: hi.y - sr * 0.8, width: sr * 2, height: sr * 1.6))
        }
    }

    // MARK: - Boulder

    static func boulder(diameter: CGFloat) -> SKTexture {
        let pad = diameter * 0.18
        let size = CGSize(width: diameter + pad * 2, height: diameter + pad * 2)
        return cached("boulder", size: size) { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let r = diameter / 2
            // irregular rock silhouette
            let pts: [CGPoint] = [
                CGPoint(x: -0.95, y: -0.2), CGPoint(x: -0.75, y: 0.55), CGPoint(x: -0.2, y: 0.95),
                CGPoint(x: 0.5, y: 0.82), CGPoint(x: 0.95, y: 0.3), CGPoint(x: 0.85, y: -0.45),
                CGPoint(x: 0.35, y: -0.95), CGPoint(x: -0.45, y: -0.9)
            ].map { CGPoint(x: c.x + $0.x * r, y: c.y + $0.y * r) }
            let path = CGMutablePath()
            path.addLines(between: pts); path.closeSubpath()

            // shadow
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: diameter * 0.05),
                          blur: diameter * 0.14, color: SKColor.black.withAlphaComponent(0.35).cgColor)
            ctx.addPath(path); ctx.setFillColor(SKColor(white: 0.4, alpha: 1).cgColor); ctx.fillPath()
            ctx.restoreGState()

            // gradient body (lit top; y-down so top is smaller y)
            ctx.saveGState()
            ctx.addPath(path); ctx.clip()
            let cgcs = CGColorSpaceCreateDeviceRGB()
            let top = SKColor(red: 0.58, green: 0.55, blue: 0.53, alpha: 1)
            let bot = SKColor(red: 0.30, green: 0.28, blue: 0.27, alpha: 1)
            let grad = CGGradient(colorsSpace: cgcs, colors: [top.cgColor, bot.cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.drawLinearGradient(grad, start: CGPoint(x: c.x, y: c.y - r),
                                   end: CGPoint(x: c.x, y: c.y + r), options: [])
            // cracks
            ctx.setStrokeColor(SKColor(white: 0.18, alpha: 0.6).cgColor)
            ctx.setLineWidth(diameter * 0.025); ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.5))
            ctx.addLine(to: CGPoint(x: c.x + r * 0.05, y: c.y))
            ctx.addLine(to: CGPoint(x: c.x + r * 0.5, y: c.y - r * 0.1))
            ctx.move(to: CGPoint(x: c.x + r * 0.1, y: c.y))
            ctx.addLine(to: CGPoint(x: c.x - r * 0.1, y: c.y - r * 0.6))
            ctx.strokePath()
            // speckles
            for p in [CGPoint(x: -0.4, y: 0.2), CGPoint(x: 0.3, y: 0.45), CGPoint(x: 0.55, y: -0.4),
                      CGPoint(x: -0.2, y: -0.5)] {
                ctx.setFillColor(SKColor(white: 0.72, alpha: 0.4).cgColor)
                ctx.fillEllipse(in: CGRect(x: c.x + p.x * r - 3, y: c.y + p.y * r - 3, width: 6, height: 6))
            }
            ctx.restoreGState()

            // rim light
            ctx.addPath(path)
            ctx.setStrokeColor(SKColor(white: 0.78, alpha: 0.5).cgColor)
            ctx.setLineWidth(diameter * 0.02); ctx.strokePath()
        }
    }

    // MARK: - Clouds / mist

    static func cloud(width: CGFloat) -> SKTexture {
        let size = CGSize(width: width, height: width * 0.62)
        return cached("cloud-\(Int(width))", size: size) { ctx, sz in
            ctx.setFillColor(SKColor.white.withAlphaComponent(0.92).cgColor)
            let puffs: [(CGFloat, CGFloat, CGFloat)] = [
                (0.30, 0.42, 0.26), (0.50, 0.55, 0.32), (0.70, 0.45, 0.27), (0.50, 0.40, 0.24)
            ]
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: -3), blur: 10,
                          color: SKColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 0.4).cgColor)
            for (fx, fy, fr) in puffs {
                let r = fr * sz.width
                ctx.fillEllipse(in: CGRect(x: fx * sz.width - r, y: fy * sz.height - r * 0.8,
                                           width: r * 2, height: r * 1.6))
            }
            ctx.restoreGState()
        }
    }

    // MARK: - Soft shadow blob (ground telegraph)

    static func softShadow(diameter: CGFloat) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        return cached("softshadow", size: size) { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let cgcs = CGColorSpaceCreateDeviceRGB()
            let grad = CGGradient(colorsSpace: cgcs,
                                  colors: [SKColor.black.withAlphaComponent(0.45).cgColor,
                                           SKColor.black.withAlphaComponent(0).cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0,
                                   endCenter: c, endRadius: sz.width / 2, options: [])
        }
    }

    // MARK: - Coin

    static func coin(diameter: CGFloat) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        return cached("coin", size: size) { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let r = diameter / 2
            let cgcs = CGColorSpaceCreateDeviceRGB()
            let grad = CGGradient(colorsSpace: cgcs,
                                  colors: [SKColor(red: 1, green: 0.93, blue: 0.5, alpha: 1).cgColor,
                                           SKColor(red: 0.95, green: 0.7, blue: 0.12, alpha: 1).cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.saveGState()
            ctx.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)); ctx.clip()
            ctx.drawRadialGradient(grad, startCenter: CGPoint(x: c.x - r * 0.3, y: c.y - r * 0.3),
                                   startRadius: 0, endCenter: c, endRadius: r * 1.1, options: [.drawsAfterEndLocation])
            ctx.restoreGState()
            ctx.setStrokeColor(SKColor(red: 0.8, green: 0.55, blue: 0.06, alpha: 1).cgColor)
            ctx.setLineWidth(diameter * 0.08)
            ctx.strokeEllipse(in: CGRect(x: c.x - r * 0.92, y: c.y - r * 0.92, width: r * 1.84, height: r * 1.84))
            ctx.setFillColor(SKColor.white.withAlphaComponent(0.6).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r * 0.5, y: c.y - r * 0.55, width: r * 0.4, height: r * 0.55))
        }
    }

    // MARK: - Candy

    static func candy(diameter d: CGFloat) -> SKTexture {
        let size = CGSize(width: d * 1.7, height: d)
        return cached("candy", size: size) { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let r = d / 2
            let pink = SKColor(red: 1.0, green: 0.43, blue: 0.66, alpha: 1)
            let cgcs = CGColorSpaceCreateDeviceRGB()

            // wrapper ends (triangles)
            ctx.setFillColor(pink.darker(0.05).cgColor)
            for sgn in [CGFloat(-1), 1] {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: c.x + sgn * r * 0.7, y: c.y))
                p.addLine(to: CGPoint(x: c.x + sgn * r * 1.35, y: c.y - r * 0.5))
                p.addLine(to: CGPoint(x: c.x + sgn * r * 1.35, y: c.y + r * 0.5))
                p.closeSubpath()
                ctx.addPath(p); ctx.fillPath()
            }
            // body (glossy)
            ctx.saveGState()
            let body = CGRect(x: c.x - r * 0.85, y: c.y - r * 0.7, width: r * 1.7, height: r * 1.4)
            ctx.addEllipse(in: body); ctx.clip()
            let grad = CGGradient(colorsSpace: cgcs,
                                  colors: [pink.lighter(0.28).cgColor, pink.darker(0.18).cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.drawRadialGradient(grad, startCenter: CGPoint(x: c.x - r * 0.3, y: c.y - r * 0.3),
                                   startRadius: 0, endCenter: c, endRadius: r, options: [.drawsAfterEndLocation])
            // diagonal stripe
            ctx.setStrokeColor(SKColor.white.withAlphaComponent(0.7).cgColor)
            ctx.setLineWidth(r * 0.18)
            ctx.move(to: CGPoint(x: c.x - r * 0.6, y: c.y + r * 0.5))
            ctx.addLine(to: CGPoint(x: c.x + r * 0.6, y: c.y - r * 0.5))
            ctx.strokePath()
            ctx.restoreGState()
            // gloss
            ctx.setFillColor(SKColor.white.withAlphaComponent(0.55).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r * 0.55, y: c.y - r * 0.5, width: r * 0.5, height: r * 0.32))
        }
    }

    // MARK: - Gem

    static func gem(diameter d: CGFloat) -> SKTexture {
        let size = CGSize(width: d, height: d * 1.1)
        return cached("gem", size: size) { ctx, sz in
            let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let r = d / 2
            let cgcs = CGColorSpaceCreateDeviceRGB()
            let blue = SKColor(red: 0.30, green: 0.78, blue: 1.0, alpha: 1)
            // diamond silhouette
            let pts = [CGPoint(x: c.x, y: c.y - r),            // bottom
                       CGPoint(x: c.x - r * 0.9, y: c.y + r * 0.25),
                       CGPoint(x: c.x - r * 0.5, y: c.y + r),  // top-left
                       CGPoint(x: c.x + r * 0.5, y: c.y + r),  // top-right
                       CGPoint(x: c.x + r * 0.9, y: c.y + r * 0.25)]
            let path = CGMutablePath(); path.addLines(between: pts); path.closeSubpath()
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: 4), blur: 8,
                          color: blue.darker(0.2).withAlphaComponent(0.6).cgColor)
            ctx.addPath(path); ctx.setFillColor(blue.cgColor); ctx.fillPath()
            ctx.restoreGState()
            ctx.saveGState(); ctx.addPath(path); ctx.clip()
            let grad = CGGradient(colorsSpace: cgcs,
                                  colors: [blue.lighter(0.35).cgColor, blue.darker(0.22).cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: c.y - r),
                                   end: CGPoint(x: 0, y: c.y + r), options: [])
            // facet lines
            ctx.setStrokeColor(SKColor.white.withAlphaComponent(0.5).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: c.x - r * 0.5, y: c.y + r)); ctx.addLine(to: CGPoint(x: c.x, y: c.y - r))
            ctx.move(to: CGPoint(x: c.x + r * 0.5, y: c.y + r)); ctx.addLine(to: CGPoint(x: c.x, y: c.y - r))
            ctx.move(to: CGPoint(x: c.x - r * 0.9, y: c.y + r * 0.25))
            ctx.addLine(to: CGPoint(x: c.x + r * 0.9, y: c.y + r * 0.25))
            ctx.strokePath()
            ctx.restoreGState()
            // sparkle
            ctx.setFillColor(SKColor.white.withAlphaComponent(0.8).cgColor)
            ctx.fillEllipse(in: CGRect(x: c.x - r * 0.32, y: c.y + r * 0.32, width: r * 0.22, height: r * 0.22))
        }
    }

    // MARK: - Mountain layer (misty, atmospheric)

    /// A single ridge silhouette with a snow cap and atmospheric haze toward the base.
    static func mountain(width: CGFloat, height: CGFloat, base: SKColor, snow: Bool, key: String) -> SKTexture {
        let size = CGSize(width: width, height: height)
        return cached("mtn-\(key)", size: size) { ctx, sz in
            let w = sz.width, h = sz.height
            // y-down context: base sits along the bottom (y=h), peaks rise toward y=0.
            // `fy` is peak tallness (1 = tallest); ridge y = (1 - fy) * h.
            let peaks: [(CGFloat, CGFloat)] = [
                (0.0, 0.20), (0.12, 0.55), (0.22, 0.40), (0.34, 0.82), (0.46, 0.52),
                (0.58, 0.95), (0.70, 0.50), (0.82, 0.74), (0.92, 0.44), (1.0, 0.62)
            ]
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: h))
            for (fx, fy) in peaks { path.addLine(to: CGPoint(x: fx * w, y: (1 - fy) * h)) }
            path.addLine(to: CGPoint(x: w, y: h)); path.closeSubpath()

            ctx.saveGState(); ctx.addPath(path); ctx.clip()
            let cgcs = CGColorSpaceCreateDeviceRGB()
            // hazier (lighter) toward the base for atmospheric depth
            let topC = base.lighter(0.04)
            let hazeC = base.lighter(0.34)
            let grad = CGGradient(colorsSpace: cgcs, colors: [topC.cgColor, hazeC.cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: h), options: [])
            ctx.restoreGState()

            if snow {
                ctx.saveGState(); ctx.addPath(path); ctx.clip()
                ctx.setFillColor(SKColor(white: 0.97, alpha: 0.92).cgColor)
                for (fx, fy) in peaks where fy > 0.7 {
                    let px = fx * w, py = (1 - fy) * h
                    let cap = CGMutablePath()
                    cap.move(to: CGPoint(x: px - w * 0.05, y: py + h * 0.14))
                    cap.addLine(to: CGPoint(x: px, y: py - h * 0.02))
                    cap.addLine(to: CGPoint(x: px + w * 0.05, y: py + h * 0.14))
                    cap.closeSubpath()
                    ctx.addPath(cap); ctx.fillPath()
                }
                ctx.restoreGState()
            }
        }
    }

    // MARK: - Candy button

    /// A glossy 3D "candy" button: drop shadow, darker bottom lip, gradient face,
    /// top sheen and outline. Returns a texture padded for the shadow; the visual
    /// button occupies the centre `width`×`height`.
    static func button(width: CGFloat, height: CGFloat, color: SKColor, key: String) -> SKTexture {
        let pad: CGFloat = 20
        let size = CGSize(width: width + pad * 2, height: height + pad * 2)
        return cached("btn-\(key)", size: size) { ctx, sz in
            let rect = CGRect(x: pad, y: pad, width: width, height: height)
            let corner = height / 2
            let cgcs = CGColorSpaceCreateDeviceRGB()

            // drop shadow under the lip
            ctx.saveGState()
            ctx.setShadow(offset: CGSize(width: 0, height: 7), blur: 12,
                          color: SKColor.black.withAlphaComponent(0.35).cgColor)
            let lip = CGPath(roundedRect: rect.offsetBy(dx: 0, dy: 6), cornerWidth: corner,
                             cornerHeight: corner, transform: nil)
            ctx.addPath(lip); ctx.setFillColor(color.darker(0.26).cgColor); ctx.fillPath()
            ctx.restoreGState()

            // gradient face
            let face = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
            ctx.saveGState(); ctx.addPath(face); ctx.clip()
            let grad = CGGradient(colorsSpace: cgcs,
                                  colors: [color.lighter(0.16).cgColor, color.darker(0.04).cgColor] as CFArray,
                                  locations: [0, 1])!
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: rect.minY),
                                   end: CGPoint(x: 0, y: rect.maxY), options: [])
            // top sheen
            ctx.setFillColor(SKColor.white.withAlphaComponent(0.30).cgColor)
            let sheen = CGPath(roundedRect: CGRect(x: rect.minX + 10, y: rect.minY + 6,
                                                   width: rect.width - 20, height: rect.height * 0.40),
                               cornerWidth: corner * 0.6, cornerHeight: corner * 0.6, transform: nil)
            ctx.addPath(sheen); ctx.fillPath()
            ctx.restoreGState()

            // outline
            ctx.addPath(face)
            ctx.setStrokeColor(color.darker(0.32).cgColor)
            ctx.setLineWidth(3); ctx.strokePath()
        }
    }

    /// Vertical multi-stop gradient texture (for skies).
    static func verticalGradient(size: CGSize, colors: [SKColor], locations: [CGFloat], key: String) -> SKTexture {
        return cached("vgrad-\(key)", size: size) { ctx, sz in
            let cgcs = CGColorSpaceCreateDeviceRGB()
            let grad = CGGradient(colorsSpace: cgcs, colors: colors.map { $0.cgColor } as CFArray,
                                  locations: locations)!
            ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: sz.height),
                                   end: CGPoint(x: 0, y: 0), options: [])
        }
    }
}
