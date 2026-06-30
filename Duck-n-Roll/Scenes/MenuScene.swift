//
//  MenuScene.swift
//  Duck-n-Roll
//
//  Title screen: shows coins, the current evolution form, a level chooser, and
//  routes into the game or the upgrade shop.
//

import SpriteKit

final class MenuScene: SKScene {

    private let state = GameState.shared
    private var selectedLevel = 1

    private let coinLabel = SKLabelNode(fontNamed: FontName.bold)
    private let levelLabel = SKLabelNode(fontNamed: FontName.heavy)
    private let stageLabel = SKLabelNode(fontNamed: FontName.demi)
    private var previewDuck: PlayerNode?

    private let playButton    = ButtonNode(text: "PLAY", color: Palette.coin)
    private let upgradeButton = ButtonNode(text: "UPGRADES", color: Palette.projectile)
    private let prevButton    = ButtonNode(text: "◀", size: CGSize(width: 56, height: 56), color: .white, fontSize: 26)
    private let nextButton    = ButtonNode(text: "▶", size: CGSize(width: 56, height: 56), color: .white, fontSize: 26)

    override func didMove(to view: SKView) {
        backgroundColor = Palette.skyBottom
        Backdrop.install(in: self)
        Haptics.shared.prepareAll()
        selectedLevel = min(state.highestLevel, LevelConfig.maxLevel)
        buildUI()
        refresh()
    }

    private func buildUI() {
        let w = size.width, h = size.height

        // Title logo
        let logo = SKSpriteNode(texture: SKTexture(imageNamed: "Logo"))
        let logoW = w * 0.84
        logo.size = CGSize(width: logoW, height: logoW * (820.0 / 1500.0))
        logo.position = CGPoint(x: w / 2, y: h * 0.85)
        logo.zPosition = Z.hud
        addChild(logo)
        logo.run(.repeatForever(.sequence([
            .scale(to: 1.03, duration: 1.6), .scale(to: 1.0, duration: 1.6)])))

        let subtitle = SKLabelNode(fontNamed: FontName.demi)
        subtitle.text = "Spell • Dodge • Evolve"
        subtitle.fontSize = 16
        subtitle.fontColor = .white
        subtitle.position = CGPoint(x: w / 2, y: h * 0.75)
        subtitle.zPosition = Z.hud
        let subShadow = SKLabelNode(fontNamed: FontName.demi)
        subShadow.text = subtitle.text; subShadow.fontSize = 16
        subShadow.fontColor = SKColor.black.withAlphaComponent(0.35)
        subShadow.position = CGPoint(x: w / 2 + 1, y: h * 0.75 - 1.5)
        subShadow.zPosition = Z.hud - 0.1
        addChild(subShadow)
        addChild(subtitle)

        // Coins pill
        let coinPill = SKShapeNode(rectOf: CGSize(width: 150, height: 42), cornerRadius: 21)
        coinPill.fillColor = Palette.panel
        coinPill.strokeColor = Palette.coin
        coinPill.lineWidth = 2
        coinPill.position = CGPoint(x: w / 2, y: h * 0.70)
        coinPill.zPosition = Z.hud
        addChild(coinPill)
        let coinIcon = SKSpriteNode(texture: TextureFactory.coin(diameter: 26))
        coinIcon.position = CGPoint(x: -50, y: 0)
        coinPill.addChild(coinIcon)
        coinLabel.fontSize = 22
        coinLabel.fontColor = .white
        coinLabel.verticalAlignmentMode = .center
        coinLabel.position = CGPoint(x: 8, y: 0)
        coinPill.addChild(coinLabel)

        // Evolution preview
        let duck = PlayerNode()
        duck.position = CGPoint(x: w / 2, y: h * 0.56)
        duck.zPosition = Z.player
        duck.startIdleBob()
        addChild(duck)
        previewDuck = duck

        stageLabel.fontSize = 22
        stageLabel.fontColor = Palette.ink
        stageLabel.position = CGPoint(x: w / 2, y: h * 0.46)
        stageLabel.zPosition = Z.hud
        addChild(stageLabel)

        // Level chooser row
        levelLabel.fontSize = 28
        levelLabel.fontColor = Palette.ink
        levelLabel.verticalAlignmentMode = .center
        levelLabel.position = CGPoint(x: w / 2, y: h * 0.37)
        levelLabel.zPosition = Z.hud
        addChild(levelLabel)

        prevButton.position = CGPoint(x: w / 2 - 110, y: h * 0.37)
        prevButton.zPosition = Z.hud
        addChild(prevButton)
        nextButton.position = CGPoint(x: w / 2 + 110, y: h * 0.37)
        nextButton.zPosition = Z.hud
        addChild(nextButton)

        // Action buttons
        playButton.position = CGPoint(x: w / 2, y: h * 0.24)
        playButton.zPosition = Z.hud
        addChild(playButton)

        upgradeButton.position = CGPoint(x: w / 2, y: h * 0.15)
        upgradeButton.zPosition = Z.hud
        addChild(upgradeButton)

        // Hint
        let hint = SKLabelNode(fontNamed: FontName.demi)
        hint.text = "Shoot the letters in order to spell the word • dodge balls • home for quakes"
        hint.fontSize = 12
        hint.fontColor = Palette.ink.withAlphaComponent(0.7)
        hint.position = CGPoint(x: w / 2, y: h * 0.07)
        hint.zPosition = Z.hud
        addChild(hint)
    }

    private func refresh() {
        coinLabel.text = "\(state.coins)"
        levelLabel.text = "Level \(selectedLevel)"
        let stage = EvolutionStage.stage(forLevel: selectedLevel)
        // Preview what this level asks you to spell.
        let cfg = LevelConfig.config(for: selectedLevel)
        switch cfg.mode {
        case .word:   stageLabel.text = "Spell:  \(WordBank.word(forLevel: selectedLevel).word)"
        case .streak: stageLabel.text = "★ Streak round! ★"
        case .boss:   stageLabel.text = "Boss spell-off!"
        }
        previewDuck?.configure(for: stage)
        previewDuck?.startIdleBob()
        prevButton.setEnabled(selectedLevel > 1)
        nextButton.setEnabled(selectedLevel < state.highestLevel)
    }

    // MARK: - Touch routing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self) else { return }
        if [prevButton, nextButton, playButton, upgradeButton].contains(where: { $0.contains(parentPoint: p) }) {
            Haptics.shared.uiTap()
        }

        if prevButton.contains(parentPoint: p) {
            prevButton.animatePress()
            selectedLevel = max(1, selectedLevel - 1); refresh()
        } else if nextButton.contains(parentPoint: p) {
            nextButton.animatePress()
            selectedLevel = min(state.highestLevel, selectedLevel + 1); refresh()
        } else if playButton.contains(parentPoint: p) {
            playButton.animatePress()
            startLevel(selectedLevel)
        } else if upgradeButton.contains(parentPoint: p) {
            upgradeButton.animatePress()
            presentUpgrades()
        }
    }

    private func startLevel(_ level: Int) {
        state.currentLevel = level
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .doorway(withDuration: 0.5))
    }

    private func presentUpgrades() {
        let scene = UpgradeScene(size: size)
        scene.scaleMode = scaleMode
        scene.returnLevel = selectedLevel
        view?.presentScene(scene, transition: .push(with: .left, duration: 0.35))
    }
}
