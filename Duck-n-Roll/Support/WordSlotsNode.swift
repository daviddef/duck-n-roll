//
//  WordSlotsNode.swift
//  Duck-n-Roll
//
//  The target word shown at the top of the play screen as a row of letter tiles.
//  Locked letters fill in green; the next letter you need glows so a young player
//  always knows what to hunt for.
//

import SpriteKit

final class WordSlotsNode: SKNode {

    private struct Tile { let bg: SKShapeNode; let label: SKLabelNode }
    private var tiles: [Tile] = []
    private var letters: [Character] = []

    private let tileW: CGFloat = 34
    private let tileH: CGFloat = 42
    private let gap: CGFloat = 7

    private let filled = SKColor(red: 0.36, green: 0.74, blue: 0.36, alpha: 1)
    private let pending = Palette.panel
    private let nextHi = SKColor(red: 1.0, green: 0.82, blue: 0.25, alpha: 1)

    func setWord(_ word: [Character]) {
        removeAllChildren()
        tiles.removeAll()
        letters = word

        let n = word.count
        let total = CGFloat(n) * tileW + CGFloat(max(0, n - 1)) * gap
        let startX = -total / 2 + tileW / 2

        for i in 0..<n {
            let bg = SKShapeNode(rectOf: CGSize(width: tileW, height: tileH), cornerRadius: 7)
            bg.fillColor = pending
            bg.strokeColor = .white
            bg.lineWidth = 1.5
            bg.position = CGPoint(x: startX + CGFloat(i) * (tileW + gap), y: 0)
            addChild(bg)

            let label = SKLabelNode(fontNamed: FontName.heavy)
            label.text = String(word[i])
            label.fontSize = 24
            label.fontColor = .white
            label.alpha = 0.0           // hidden until locked
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = bg.position
            addChild(label)

            tiles.append(Tile(bg: bg, label: label))
        }
        lock(upTo: 0)
    }

    /// Show the first `index` letters as locked and glow the `index`-th (next).
    func lock(upTo index: Int) {
        for (i, tile) in tiles.enumerated() {
            tile.bg.removeAction(forKey: "pulse")
            if i < index {
                tile.bg.fillColor = filled
                tile.bg.strokeColor = .white
                tile.label.alpha = 1
            } else if i == index {
                tile.bg.fillColor = nextHi
                tile.bg.strokeColor = .white
                tile.label.alpha = 0.25
                tile.bg.run(.repeatForever(.sequence([
                    .scale(to: 1.12, duration: 0.45), .scale(to: 1.0, duration: 0.45)])), withKey: "pulse")
            } else {
                tile.bg.fillColor = pending
                tile.bg.strokeColor = .white
                tile.label.alpha = 0.0
                tile.bg.setScale(1.0)
            }
        }
    }

    /// Pop the just-locked tile for feedback.
    func popLocked(_ index: Int) {
        guard index >= 0 && index < tiles.count else { return }
        let t = tiles[index]
        t.label.alpha = 1
        t.bg.run(.sequence([.scale(to: 1.3, duration: 0.1), .scale(to: 1.0, duration: 0.12)]))
    }

    /// Brief red shudder on the next tile for a wrong guess.
    func shakeNext(_ index: Int) {
        guard index >= 0 && index < tiles.count else { return }
        let t = tiles[index]
        let orig = t.bg.position
        t.bg.run(.sequence([
            .moveBy(x: -5, y: 0, duration: 0.04), .moveBy(x: 10, y: 0, duration: 0.04),
            .moveBy(x: -10, y: 0, duration: 0.04), .moveBy(x: 5, y: 0, duration: 0.04),
            .move(to: orig, duration: 0.02)]))
    }
}
