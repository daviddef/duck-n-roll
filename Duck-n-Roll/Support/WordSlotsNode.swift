//
//  WordSlotsNode.swift
//  Duck-n-Roll
//
//  The target word shown at the top of the play screen as a row of big,
//  high-contrast letter tiles on a dark backing tray (so they read clearly over
//  the painterly sky). Locked letters fill green; the next letter you need glows
//  gold with the letter shown so a young player knows exactly what to hunt for.
//

import SpriteKit

final class WordSlotsNode: SKNode {

    private struct Tile {
        let container: SKNode
        let bg: SKShapeNode
        let label: SKLabelNode
        let shadow: SKLabelNode
    }
    private var tiles: [Tile] = []
    private var letters: [Character] = []

    // High-contrast palette
    private let filled  = SKColor(red: 0.28, green: 0.78, blue: 0.34, alpha: 1)   // bright green
    private let pending = SKColor(red: 0.15, green: 0.18, blue: 0.28, alpha: 1)   // opaque slate
    private let nextHi  = SKColor(red: 1.00, green: 0.80, blue: 0.16, alpha: 1)   // bright gold
    private let ink     = SKColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1)

    /// Lay out the word, sizing tiles as large as possible within `maxWidth`.
    func setWord(_ word: [Character], maxWidth: CGFloat) {
        removeAllChildren()
        tiles.removeAll()
        letters = word

        let n = max(1, word.count)
        let gap: CGFloat = 8
        var tw: CGFloat = 48
        if CGFloat(n) * tw + CGFloat(n - 1) * gap > maxWidth {
            tw = (maxWidth - CGFloat(n - 1) * gap) / CGFloat(n)
        }
        let th = tw * 1.24
        let font = th * 0.62
        let total = CGFloat(n) * tw + CGFloat(n - 1) * gap

        // Backing tray for contrast against the sky/clouds.
        let tray = SKShapeNode(rectOf: CGSize(width: total + 22, height: th + 18), cornerRadius: 16)
        tray.fillColor = SKColor(red: 0.06, green: 0.08, blue: 0.16, alpha: 0.55)
        tray.strokeColor = SKColor.white.withAlphaComponent(0.22)
        tray.lineWidth = 1.5
        tray.zPosition = -1
        addChild(tray)

        let startX = -total / 2 + tw / 2
        let corner = tw * 0.24
        for i in 0..<n {
            let container = SKNode()
            container.position = CGPoint(x: startX + CGFloat(i) * (tw + gap), y: 0)
            addChild(container)

            // 3D lip
            let lip = SKShapeNode(rectOf: CGSize(width: tw, height: th), cornerRadius: corner)
            lip.fillColor = SKColor.black.withAlphaComponent(0.35)
            lip.strokeColor = .clear
            lip.position = CGPoint(x: 0, y: -3)
            container.addChild(lip)

            let bg = SKShapeNode(rectOf: CGSize(width: tw, height: th), cornerRadius: corner)
            bg.lineWidth = 3
            bg.zPosition = 1
            container.addChild(bg)

            // drop-shadow letter for legibility on any tile colour
            let shadow = SKLabelNode(fontNamed: FontName.heavy)
            shadow.text = String(word[i]); shadow.fontSize = font
            shadow.fontColor = SKColor.black.withAlphaComponent(0.45)
            shadow.verticalAlignmentMode = .center; shadow.horizontalAlignmentMode = .center
            shadow.position = CGPoint(x: 1.5, y: -2); shadow.zPosition = 2
            container.addChild(shadow)

            let label = SKLabelNode(fontNamed: FontName.heavy)
            label.text = String(word[i]); label.fontSize = font
            label.verticalAlignmentMode = .center; label.horizontalAlignmentMode = .center
            label.zPosition = 3
            container.addChild(label)

            tiles.append(Tile(container: container, bg: bg, label: label, shadow: shadow))
        }
        lock(upTo: 0)
    }

    /// Show the first `index` letters as locked and glow the `index`-th (next).
    func lock(upTo index: Int) {
        for (i, t) in tiles.enumerated() {
            t.container.removeAction(forKey: "pulse")
            t.container.setScale(1.0)
            if i < index {
                t.bg.fillColor = filled
                t.bg.strokeColor = .white
                t.label.fontColor = .white; t.label.alpha = 1
                t.shadow.alpha = 0.5
            } else if i == index {
                t.bg.fillColor = nextHi
                t.bg.strokeColor = .white
                t.label.fontColor = ink; t.label.alpha = 1   // dark letter on gold = readable target
                t.shadow.alpha = 0
                t.container.run(.repeatForever(.sequence([
                    .scale(to: 1.10, duration: 0.45), .scale(to: 1.0, duration: 0.45)])), withKey: "pulse")
            } else {
                t.bg.fillColor = pending
                t.bg.strokeColor = SKColor.white.withAlphaComponent(0.85)
                t.label.alpha = 0
                t.shadow.alpha = 0
            }
        }
    }

    func popLocked(_ index: Int) {
        guard index >= 0 && index < tiles.count else { return }
        tiles[index].container.run(.sequence([
            .scale(to: 1.32, duration: 0.1), .scale(to: 1.0, duration: 0.12)]))
    }

    func shakeNext(_ index: Int) {
        guard index >= 0 && index < tiles.count else { return }
        let c = tiles[index].container
        let orig = c.position
        c.run(.sequence([
            .moveBy(x: -5, y: 0, duration: 0.04), .moveBy(x: 10, y: 0, duration: 0.04),
            .moveBy(x: -10, y: 0, duration: 0.04), .moveBy(x: 5, y: 0, duration: 0.04),
            .move(to: orig, duration: 0.02)]))
    }
}
