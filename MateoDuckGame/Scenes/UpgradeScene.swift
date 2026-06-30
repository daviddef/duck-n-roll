//
//  UpgradeScene.swift
//  MateoDuckGame
//
//  Spend coins on permanent Speed and Jump upgrades. Reachable from the menu and
//  shown automatically after clearing a level.
//

import SpriteKit

final class UpgradeScene: SKScene {

    /// Level to return to / continue into when leaving.
    var returnLevel: Int = 1
    /// If true, "Continue" advances into the next level instead of the menu.
    var continueToNextLevel = false

    private let state = GameState.shared
    private let coinLabel = SKLabelNode(fontNamed: FontName.bold)

    private let speedBuy  = ButtonNode(text: "", size: CGSize(width: 200, height: 52), color: Palette.coin, fontSize: 18)
    private let jumpBuy   = ButtonNode(text: "", size: CGSize(width: 200, height: 52), color: Palette.coin, fontSize: 18)
    private let continueButton = ButtonNode(text: "CONTINUE", color: Palette.projectile)

    private let speedPips = SKNode()
    private let jumpPips = SKNode()

    override func didMove(to view: SKView) {
        backgroundColor = Palette.skyBottom
        Backdrop.install(in: self)
        buildUI()
        refresh()
    }

    private func buildUI() {
        let w = size.width, h = size.height

        let title = SKLabelNode(fontNamed: FontName.heavy)
        title.text = "UPGRADE SHOP"
        title.fontSize = 34
        title.fontColor = Palette.ink
        title.position = CGPoint(x: w / 2, y: h * 0.88)
        title.zPosition = Z.hud
        addChild(title)

        // Coins
        let coinPill = SKShapeNode(rectOf: CGSize(width: 160, height: 42), cornerRadius: 21)
        coinPill.fillColor = Palette.panel
        coinPill.strokeColor = Palette.coin
        coinPill.lineWidth = 2
        coinPill.position = CGPoint(x: w / 2, y: h * 0.80)
        coinPill.zPosition = Z.hud
        addChild(coinPill)
        let coinIcon = SKShapeNode(circleOfRadius: 11)
        coinIcon.fillColor = Palette.coin
        coinIcon.position = CGPoint(x: -54, y: 0)
        coinPill.addChild(coinIcon)
        coinLabel.fontSize = 22
        coinLabel.fontColor = .white
        coinLabel.verticalAlignmentMode = .center
        coinLabel.position = CGPoint(x: 6, y: 0)
        coinPill.addChild(coinLabel)

        makeUpgradeCard(title: "SPEED", subtitle: "Move faster left & right",
                        y: h * 0.62, buyButton: speedBuy, pips: speedPips)
        makeUpgradeCard(title: "JUMP", subtitle: "Higher hops, longer hang time",
                        y: h * 0.42, buyButton: jumpBuy, pips: jumpPips)

        continueButton.position = CGPoint(x: w / 2, y: h * 0.16)
        continueButton.zPosition = Z.hud
        addChild(continueButton)
    }

    private func makeUpgradeCard(title: String, subtitle: String, y: CGFloat,
                                 buyButton: ButtonNode, pips: SKNode) {
        let w = size.width
        let card = SKShapeNode(rectOf: CGSize(width: w * 0.82, height: 150), cornerRadius: 16)
        card.fillColor = Palette.panel
        card.strokeColor = .white
        card.lineWidth = 1.5
        card.position = CGPoint(x: w / 2, y: y)
        card.zPosition = Z.hud
        addChild(card)

        let t = SKLabelNode(fontNamed: FontName.heavy)
        t.text = title
        t.fontSize = 26
        t.fontColor = .white
        t.horizontalAlignmentMode = .left
        t.position = CGPoint(x: -w * 0.36, y: 38)
        card.addChild(t)

        let s = SKLabelNode(fontNamed: FontName.demi)
        s.text = subtitle
        s.fontSize = 14
        s.fontColor = SKColor.white.withAlphaComponent(0.75)
        s.horizontalAlignmentMode = .left
        s.position = CGPoint(x: -w * 0.36, y: 16)
        card.addChild(s)

        // Pips showing tiers
        pips.position = CGPoint(x: -w * 0.36, y: -18)
        card.addChild(pips)

        // The buy button is added to the SCENE (not the card) at an absolute
        // position so its accumulated frame is in scene coordinates for hit-testing.
        buyButton.position = CGPoint(x: w / 2 + w * 0.22, y: y - 2)
        buyButton.zPosition = Z.hud + 1
        addChild(buyButton)
    }

    private func rebuildPips(_ container: SKNode, filled: Int) {
        container.removeAllChildren()
        for i in 0..<GameState.maxTier {
            let pip = SKShapeNode(rectOf: CGSize(width: 22, height: 12), cornerRadius: 3)
            pip.fillColor = i < filled ? Palette.coin : SKColor.white.withAlphaComponent(0.18)
            pip.strokeColor = .clear
            pip.position = CGPoint(x: CGFloat(i) * 28, y: 0)
            container.addChild(pip)
        }
    }

    private func refresh() {
        coinLabel.text = "\(state.coins)"
        rebuildPips(speedPips, filled: state.speedTier)
        rebuildPips(jumpPips, filled: state.jumpTier)

        configureBuy(speedBuy, tier: state.speedTier, cost: state.upgradeCost(forTier: state.speedTier))
        configureBuy(jumpBuy, tier: state.jumpTier, cost: state.upgradeCost(forTier: state.jumpTier))

        continueButton.text = continueToNextLevel ? "PLAY LEVEL \(returnLevel)" : "BACK TO MENU"
    }

    private func configureBuy(_ button: ButtonNode, tier: Int, cost: Int) {
        if tier >= GameState.maxTier {
            button.text = "MAXED"
            button.setEnabled(false)
        } else {
            button.text = "Buy  \(cost)c"
            button.setEnabled(state.coins >= cost)
            button.setColor(state.coins >= cost ? Palette.coin : SKColor.gray)
        }
    }

    // MARK: - Touch routing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        // Convert into card-local space: buttons live inside card nodes, so test
        // using scene-space accumulated frames instead.
        if frameContains(speedBuy, point: p), speedBuy.isEnabledButton {
            speedBuy.animatePress()
            if state.buySpeedUpgrade() { refresh() }
        } else if frameContains(jumpBuy, point: p), jumpBuy.isEnabledButton {
            jumpBuy.animatePress()
            if state.buyJumpUpgrade() { refresh() }
        } else if frameContains(continueButton, point: p) {
            continueButton.animatePress()
            leave()
        }
    }

    /// Hit-test a node anywhere in the tree using its accumulated scene frame.
    private func frameContains(_ node: SKNode, point: CGPoint) -> Bool {
        node.calculateAccumulatedFrame().insetBy(dx: -8, dy: -8).contains(point)
    }

    private func leave() {
        if continueToNextLevel {
            state.currentLevel = returnLevel
            let scene = GameScene(size: size)
            scene.scaleMode = scaleMode
            view?.presentScene(scene, transition: .doorway(withDuration: 0.5))
        } else {
            let scene = MenuScene(size: size)
            scene.scaleMode = scaleMode
            view?.presentScene(scene, transition: .push(with: .right, duration: 0.35))
        }
    }
}
