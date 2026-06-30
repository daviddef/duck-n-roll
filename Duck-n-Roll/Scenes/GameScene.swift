//
//  GameScene.swift
//  Duck-n-Roll
//
//  Core gameplay. Boulders & balls roll down a perspective hill; the player
//  DRAGS to run around (including up the hill to grab tokens) and TAPS to hop.
//  A small, movable SHOOT icon fires bolts. Tokens (coins/candy/gems) appear up
//  the hill for risk/reward. Periodic earthquakes force a dash into the cottage.
//

import SpriteKit

final class GameScene: SKScene {

    // MARK: - Configuration / state
    private let state = GameState.shared
    private var config = LevelConfig.config(for: 1)

    private var lives = GameState.startingLives
    private var runCoins = 0
    private var elapsed: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var lastCoinHaptic: TimeInterval = 0
    private var isRunning = true
    private var isSheltering = false
    private var graceTimer: TimeInterval = 0   // brief invulnerability at start / after spawn

    // MARK: - Spelling
    private var mode: LevelMode = .word
    private var currentEntry: WordEntry?
    private var currentWord: [Character] = []
    private var spelledIndex = 0
    private var mistakes = 0
    private var wordsCompleted = 0
    private var timeSinceNeeded: TimeInterval = 0
    private var isCelebratingWord = false
    private let wordSlots = WordSlotsNode()
    private let streakLabel = SKLabelNode(fontNamed: FontName.heavy)

    // MARK: - Layout
    private var playerStartY: CGFloat { size.height * 0.15 }
    private var roamYMin: CGFloat { size.height * 0.11 }
    private var roamYMax: CGFloat { size.height * 0.52 }
    private var spawnY: CGFloat   { size.height * 0.74 }
    private var nearPlaneY: CGFloat { size.height * 0.04 }
    private var vanishX: CGFloat { size.width / 2 }
    private let sideMargin: CGFloat = 36

    // MARK: - Nodes
    private let playfield = SKNode()
    private let hudLayer = SKNode()
    private let overlayLayer = SKNode()
    private let player = PlayerNode()
    private let hut = HutNode()
    private var boss: BossNode?

    private var obstacles: [ObstacleNode] = []
    private var collectibles: [CollectibleNode] = []
    private var projectiles: [SKNode] = []

    // MARK: - Input
    private var duckTarget: CGPoint = .zero
    private var duckTouch: UITouch?
    private var duckTouchMoved = false
    private var duckTouchStart: CGPoint = .zero
    private var shootTouch: UITouch?
    private var shootTouchMoved = false
    private var shootTouchStart: CGPoint = .zero
    private let moveThreshold: CGFloat = 14
    private var shootIcon: SKNode?
    private let shootIconRadius: CGFloat = 36

    // MARK: - Spawning / earthquake
    private var spawnAccumulator: TimeInterval = 0
    private var collectibleAccumulator: TimeInterval = 0
    private let collectibleInterval: TimeInterval = 2.1
    private var fireCooldown: TimeInterval = 0
    private enum QuakePhase { case calm, warning }
    private var quakePhase: QuakePhase = .calm
    private var quakeTimer: TimeInterval = 0

    // MARK: - HUD
    private let levelLabel = SKLabelNode(fontNamed: FontName.heavy)
    private let coinLabel = SKLabelNode(fontNamed: FontName.bold)
    private let livesLabel = SKLabelNode(fontNamed: FontName.heavy)
    private let progressFill = SKSpriteNode(color: Palette.coin, size: CGSize(width: 200, height: 12))
    private var progressBarWidth: CGFloat = 200
    private var menuButton: ButtonNode!
    private let warningBanner = SKNode()
    private let redOverlay = SKSpriteNode()
    private var panelButtons: [ButtonNode] = []

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        config = LevelConfig.config(for: state.currentLevel)
        mode = config.mode
        backgroundColor = Palette.skyBottom
        Backdrop.install(in: self)
        Haptics.shared.prepareAll()

        playfield.zPosition = 0
        addChild(playfield)
        hudLayer.zPosition = Z.hud
        addChild(hudLayer)
        overlayLayer.zPosition = Z.overlay
        addChild(overlayLayer)

        setupHut()
        setupPlayer()
        if config.isBoss { setupBoss() }
        setupHUD()
        setupWarningVisuals()
        setupSpelling()

        quakeTimer = config.quakeInterval

        isRunning = false
        runCountdownIntro()
    }

    // MARK: - Setup

    private func setupHut() {
        // Bottom-left cottage the duck runs into.
        hut.position = CGPoint(x: sideMargin + 66, y: size.height * 0.115)
        hut.zPosition = Z.hut
        playfield.addChild(hut)
    }

    private func setupPlayer() {
        player.configure(for: EvolutionStage.stage(forLevel: config.level))
        let start = CGPoint(x: size.width * 0.5, y: playerStartY)
        player.position = start
        duckTarget = start
        player.zPosition = Z.player
        player.startIdleBob()
        playfield.addChild(player)
    }

    private func setupBoss() {
        // Boss health = total correct letters needed (~5 words worth).
        let b = BossNode(maxHealth: 24)
        b.position = CGPoint(x: size.width / 2, y: size.height * 0.80)
        b.zPosition = Z.obstacle
        playfield.addChild(b)
        boss = b
    }

    // MARK: - Spelling setup

    private func setupSpelling() {
        switch mode {
        case .word:   loadWord(WordBank.word(forLevel: config.level))
        case .streak: loadWord(WordBank.randomWord(forLevel: config.level, avoiding: nil))
        case .boss:   loadWord(WordBank.randomWord(forLevel: config.level, avoiding: nil))
        }
    }

    private func loadWord(_ entry: WordEntry) {
        currentEntry = entry
        currentWord = entry.letters
        spelledIndex = 0
        timeSinceNeeded = 0
        wordSlots.setWord(currentWord, maxWidth: size.width - 96)
        // little entrance pop
        wordSlots.setScale(0.6); wordSlots.alpha = 0
        wordSlots.run(.group([.scale(to: 1.0, duration: 0.25), .fadeIn(withDuration: 0.25)]))
    }

    /// Letter to stamp on the next lettered boulder.
    private func chooseLetter() -> Character {
        let decoys = WordBank.decoyLetters(for: currentWord)
        guard spelledIndex < currentWord.count else {
            return decoys[Int.random(in: 0..<decoys.count)]
        }
        let needed = currentWord[spelledIndex]
        // Guarantee the needed letter shows up if it's been missing too long.
        let t = CGFloat(config.level - 1) / 29
        let neededProb: CGFloat = 0.58 - 0.18 * t
        if timeSinceNeeded > 3.4 || CGFloat.random(in: 0...1) < neededProb {
            timeSinceNeeded = 0
            return needed
        }
        return decoys[Int.random(in: 0..<decoys.count)]
    }

    private func setupHUD() {
        let w = size.width, h = size.height

        switch mode {
        case .boss:   levelLabel.text = "BOSS SPELL-OFF"
        case .streak: levelLabel.text = "STREAK ★ LVL \(config.level)"
        case .word:   levelLabel.text = "LEVEL \(config.level)"
        }
        levelLabel.fontSize = 16
        levelLabel.fontColor = Palette.ink
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.position = CGPoint(x: sideMargin + 44, y: h - 50)
        hudLayer.addChild(levelLabel)

        // Timer bar — only used in streak rounds (word levels track via the slots).
        progressBarWidth = min(220, w - 2 * sideMargin)
        let barBG = SKShapeNode(rectOf: CGSize(width: progressBarWidth, height: 10), cornerRadius: 5)
        barBG.fillColor = Palette.panel
        barBG.strokeColor = .white
        barBG.lineWidth = 1
        barBG.position = CGPoint(x: w / 2, y: h - 172)
        hudLayer.addChild(barBG)
        progressFill.color = Palette.coin
        progressFill.size = CGSize(width: progressBarWidth, height: 10)
        progressFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        progressFill.position = CGPoint(x: w / 2 - progressBarWidth / 2, y: h - 172)
        progressFill.xScale = 0.001
        hudLayer.addChild(progressFill)
        let showTimeBar = (mode == .streak)
        barBG.isHidden = !showTimeBar
        progressFill.isHidden = !showTimeBar

        // Coins
        let coinIcon = SKSpriteNode(texture: TextureFactory.coin(diameter: 26))
        coinIcon.position = CGPoint(x: w - sideMargin - 64, y: h - 50)
        hudLayer.addChild(coinIcon)
        coinIcon.run(.repeatForever(.sequence([
            .scaleX(to: 0.3, duration: 0.9), .scaleX(to: 1.0, duration: 0.9), .wait(forDuration: 1.2)])))
        coinLabel.text = "0"
        coinLabel.fontSize = 20
        coinLabel.fontColor = Palette.ink
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.verticalAlignmentMode = .center
        coinLabel.position = CGPoint(x: w - sideMargin - 48, y: h - 50)
        hudLayer.addChild(coinLabel)

        // Lives
        livesLabel.fontSize = 22
        livesLabel.fontColor = Palette.ball
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: w - sideMargin, y: h - 80)
        hudLayer.addChild(livesLabel)
        updateLivesLabel()

        // Word slots (the spelling target)
        wordSlots.position = CGPoint(x: w / 2, y: h - 122)
        hudLayer.addChild(wordSlots)

        // Streak counter (streak rounds only)
        streakLabel.text = "✓ 0"
        streakLabel.fontSize = 18
        streakLabel.fontColor = Palette.coin
        streakLabel.horizontalAlignmentMode = .left
        streakLabel.position = CGPoint(x: sideMargin, y: h - 172)
        streakLabel.isHidden = (mode != .streak)
        hudLayer.addChild(streakLabel)

        // Pause / menu (top-left)
        menuButton = ButtonNode(text: "II", size: CGSize(width: 42, height: 42),
                                color: .white, fontSize: 18)
        menuButton.position = CGPoint(x: sideMargin + 12, y: h - 50)
        hudLayer.addChild(menuButton)

        // Movable SHOOT icon
        if config.shootingUnlocked {
            let icon = makeShootIcon()
            icon.position = CGPoint(x: w - sideMargin - 34, y: h * 0.30)
            hudLayer.addChild(icon)
            shootIcon = icon
        }
    }

    private func makeShootIcon() -> SKNode {
        let node = SKNode()
        let bg = SKSpriteNode(texture: TextureFactory.glossySphere(diameter: 66, base: Palette.ball, key: "shootBtn"))
        node.addChild(bg)
        // lightning bolt glyph
        let bolt = SKShapeNode(path: boltPath())
        bolt.fillColor = .white
        bolt.strokeColor = Palette.ball.darker(0.3)
        bolt.lineWidth = 1.5
        bolt.zPosition = 1
        node.addChild(bolt)
        // dashed "movable" hint ring
        let ring = SKShapeNode(circleOfRadius: 40)
        ring.strokeColor = SKColor.white.withAlphaComponent(0.5)
        ring.lineWidth = 2
        ring.fillColor = .clear
        ring.zPosition = -1
        node.addChild(ring)
        ring.run(.repeatForever(.sequence([.fadeAlpha(to: 0.15, duration: 0.9),
                                           .fadeAlpha(to: 0.5, duration: 0.9)])))
        return node
    }

    private func boltPath() -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 4, y: 16))
        p.addLine(to: CGPoint(x: -8, y: 0))
        p.addLine(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: -4, y: -16))
        p.addLine(to: CGPoint(x: 9, y: 2))
        p.addLine(to: CGPoint(x: 1, y: 2))
        p.closeSubpath()
        return p
    }

    private func setupWarningVisuals() {
        redOverlay.color = Palette.warning
        redOverlay.size = size
        redOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        redOverlay.alpha = 0
        redOverlay.zPosition = Z.effects
        addChild(redOverlay)

        let bg = SKShapeNode(rectOf: CGSize(width: size.width * 0.9, height: 56), cornerRadius: 14)
        bg.fillColor = Palette.warning.withAlphaComponent(0.94)
        bg.strokeColor = .white
        bg.lineWidth = 2
        warningBanner.addChild(bg)
        let lbl = SKLabelNode(fontNamed: FontName.heavy)
        lbl.text = "⚠  EARTHQUAKE — GET HOME!"
        lbl.fontSize = 21
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        warningBanner.addChild(lbl)
        warningBanner.position = CGPoint(x: size.width / 2, y: size.height * 0.82)
        warningBanner.zPosition = Z.overlay
        warningBanner.alpha = 0
        addChild(warningBanner)
    }

    private func runCountdownIntro() {
        let label = SKLabelNode(fontNamed: FontName.heavy)
        label.fontSize = 90
        label.fontColor = Palette.ink
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        label.zPosition = Z.overlay
        label.alpha = 0
        overlayLayer.addChild(label)

        let stageName = EvolutionStage.stage(forLevel: config.level).name
        let title = SKLabelNode(fontNamed: FontName.bold)
        title.text = config.isBoss ? "FINAL BOSS" : "You are a \(stageName)!"
        title.fontSize = 24
        title.fontColor = Palette.ink
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        title.zPosition = Z.overlay
        overlayLayer.addChild(title)

        let steps = ["3", "2", "1", "GO!"]
        var actions: [SKAction] = []
        for s in steps {
            actions.append(.run { label.text = s; label.setScale(1.6); label.alpha = 1 })
            actions.append(.group([.scale(to: 1.0, duration: 0.3), .fadeAlpha(to: 0.0, duration: 0.55)]))
        }
        let finish = SKAction.run { [weak self] in
            label.removeFromParent(); title.removeFromParent()
            self?.isRunning = true
            self?.graceTimer = 1.6          // fair opening
            self?.player.flashDamage()      // blink to signal invulnerability
            self?.showControlHint()
        }
        label.run(.sequence(actions + [finish]))
    }

    private func showControlHint() {
        guard config.level == 1 else { return }
        let hint = SKLabelNode(fontNamed: FontName.demi)
        hint.text = "Drag to run • tap to hop • run up the hill for treats!"
        hint.fontSize = 14
        hint.fontColor = .white
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        hint.zPosition = Z.overlay
        let sh = SKLabelNode(fontNamed: FontName.demi)
        sh.text = hint.text; sh.fontSize = 14; sh.fontColor = SKColor.black.withAlphaComponent(0.4)
        sh.position = CGPoint(x: size.width / 2 + 1, y: size.height * 0.4 - 1.5)
        sh.zPosition = Z.overlay - 0.1
        overlayLayer.addChild(sh); overlayLayer.addChild(hint)
        let fade = SKAction.sequence([.wait(forDuration: 3.0), .fadeOut(withDuration: 0.6), .removeFromParent()])
        hint.run(fade); sh.run(fade)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isRunning && !panelButtons.isEmpty {
            for t in touches {
                let p = t.location(in: self)
                for b in panelButtons where hitTest(b, p) {
                    b.animatePress()
                    b.run(.sequence([.wait(forDuration: 0.12), .run { b.onTap?() }]))
                    return
                }
            }
            return
        }

        for t in touches {
            let p = t.location(in: self)
            if hitTest(menuButton, p) { menuButton.animatePress(); Haptics.shared.uiTap(); quitToMenu(); return }
            guard isRunning else { continue }

            if let icon = shootIcon, shootTouch == nil, dist(p, icon.position) < shootIconRadius + 8 {
                shootTouch = t; shootTouchMoved = false; shootTouchStart = p
                continue
            }
            if duckTouch == nil && !isSheltering {
                duckTouch = t; duckTouchMoved = false; duckTouchStart = p
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)
            if t === shootTouch {
                if !shootTouchMoved && dist(p, shootTouchStart) > moveThreshold { shootTouchMoved = true }
                if shootTouchMoved { shootIcon?.position = clampIcon(p) }
            } else if t === duckTouch {
                if !duckTouchMoved && dist(p, duckTouchStart) > moveThreshold { duckTouchMoved = true }
                if duckTouchMoved { duckTarget = clampRoam(p) }
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if t === shootTouch {
                if !shootTouchMoved { doShoot() }
                shootTouch = nil
            } else if t === duckTouch {
                if !duckTouchMoved && !isSheltering { doJump() }
                duckTouch = nil
            }
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if t === shootTouch { shootTouch = nil }
            else if t === duckTouch { duckTouch = nil }
        }
    }

    private func hitTest(_ node: SKNode, _ p: CGPoint) -> Bool {
        node.calculateAccumulatedFrame().insetBy(dx: -6, dy: -6).contains(p)
    }
    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
    private func clampRoam(_ p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(p.x, sideMargin), size.width - sideMargin),
                y: min(max(p.y, roamYMin), roamYMax))
    }
    private func clampIcon(_ p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(p.x, 40), size.width - 40),
                y: min(max(p.y, 40), size.height - 120))
    }

    // MARK: - Player actions

    private func doJump() {
        guard !player.isJumping else { return }
        Haptics.shared.jump()
        player.jump(power: state.jumpMultiplier) { Haptics.shared.land() }
    }

    private func doShoot() {
        guard fireCooldown <= 0 else { return }
        fireCooldown = 0.32
        Haptics.shared.shoot()
        let bolt = ProjectileNode(tint: EvolutionStage.stage(forLevel: config.level).bodyColor.lighter(0.2))
        bolt.position = CGPoint(x: player.position.x, y: player.position.y + 22)
        bolt.zPosition = Z.projectile
        playfield.addChild(bolt)
        projectiles.append(bolt)
        let flash = SKShapeNode(circleOfRadius: 14)
        flash.fillColor = Palette.projectile.withAlphaComponent(0.7)
        flash.strokeColor = .clear
        flash.position = bolt.position
        flash.zPosition = Z.projectile - 0.1
        playfield.addChild(flash)
        flash.run(.sequence([.group([.scale(to: 1.8, duration: 0.12), .fadeOut(withDuration: 0.12)]),
                             .removeFromParent()]))
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 { lastUpdate = currentTime }
        var dt = currentTime - lastUpdate
        lastUpdate = currentTime
        if dt > 1.0 / 30.0 { dt = 1.0 / 30.0 }
        guard isRunning else { return }

        if fireCooldown > 0 { fireCooldown -= dt }
        if graceTimer > 0 { graceTimer -= dt }
        timeSinceNeeded += dt

        updatePlayerMovement(dt)
        updateSpawning(dt)
        updateObstacles(dt)
        updateCollectibles(dt)
        updateProjectiles(dt)
        updateEarthquake(dt)
        updateProgress(dt)
    }

    private func updatePlayerMovement(_ dt: TimeInterval) {
        guard !isSheltering else { return }
        let maxSpeed: CGFloat = 720 * state.speedMultiplier
        let dx = duckTarget.x - player.position.x
        let dy = duckTarget.y - player.position.y
        let d = hypot(dx, dy)
        let step = maxSpeed * CGFloat(dt)
        if d <= step || d == 0 {
            player.position = duckTarget
        } else {
            player.position.x += dx / d * step
            player.position.y += dy / d * step
        }
        // Higher up the hill draws slightly behind nearer obstacles.
        player.zPosition = Z.player - (player.position.y - roamYMin) / size.height
    }

    private func updateSpawning(_ dt: TimeInterval) {
        guard quakePhase == .calm else { return }
        spawnAccumulator += dt
        if spawnAccumulator >= config.spawnInterval {
            spawnAccumulator -= config.spawnInterval
            spawnObstacle()
        }
        if !config.isBoss {
            collectibleAccumulator += dt
            if collectibleAccumulator >= collectibleInterval {
                collectibleAccumulator -= collectibleInterval
                spawnCollectible()
            }
        }
    }

    // MARK: - Obstacles

    private func spawnObstacle() {
        let isBall = CGFloat.random(in: 0...1) < config.ballChance
        // Most boulders carry a letter (the educational content); balls are pure hazards.
        var letter: Character?
        if !isBall && !isCelebratingWord && CGFloat.random(in: 0...1) < 0.82 {
            letter = chooseLetter()
        }
        let obs = ObstacleNode(kind: isBall ? .ball : .boulder, speed: config.obstacleSpeed, letter: letter)
        obs.laneX = CGFloat.random(in: sideMargin + 20 ... size.width - sideMargin - 20)
        obs.progress = 0
        positionObstacle(obs)
        playfield.addChild(obs)
        obstacles.append(obs)
    }

    private func scaleForProgress(_ p: CGFloat) -> CGFloat { 0.32 + 1.05 * p }

    private func positionObstacle(_ obs: ObstacleNode) {
        let p = obs.progress
        obs.position = CGPoint(x: vanishX + (obs.laneX - vanishX) * p,
                               y: spawnY + (nearPlaneY - spawnY) * p)
        obs.setScale(scaleForProgress(p))
        obs.zPosition = Z.obstacle + p
    }

    private func updateObstacles(_ dt: TimeInterval) {
        let travel = spawnY - nearPlaneY
        for obs in obstacles where obs.parent != nil {
            obs.progress += CGFloat(dt) * obs.rollSpeed / travel
            positionObstacle(obs)

            // Lettered boulders are friendly targets — they never hurt you.
            // Only plain rocks and balls are lethal hazards to dodge.
            if obs.letter == nil && !obs.scored && !isSheltering && graceTimer <= 0 {
                let rObs = (obs.kind == .ball ? ObstacleNode.ballDiameter : ObstacleNode.boulderDiameter)
                    / 2 * obs.xScale
                let dx = obs.position.x - player.position.x
                let dy = obs.position.y - player.position.y
                let thresh = rObs * 0.72 + 18 * player.stage.scale
                if dx * dx + dy * dy < thresh * thresh {
                    if obs.kind.canBeJumped && player.isJumping {
                        awardAvoided(obs, hopped: true)
                    } else if player.isInvulnerable {
                        // pass during i-frames
                    } else {
                        takeHit(from: obs)
                    }
                }
            }
            if obs.progress >= 1.0 && !obs.scored {
                if obs.letter == nil {
                    awardAvoided(obs)          // dodged a hazard -> coins
                } else {
                    obs.scored = true          // a letter rolled past unshot -> quietly gone
                    obs.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
                }
            }
            if obs.progress >= 1.2 { obs.removeFromParent() }
        }
        obstacles.removeAll { $0.parent == nil }
    }

    private func awardAvoided(_ obs: ObstacleNode, hopped: Bool = false) {
        guard !obs.scored else { return }
        obs.scored = true
        let reward = obs.kind.coinReward
        addCoins(reward)
        floatingText("+\(reward)", at: obs.position, color: Palette.coin)
        obs.run(.sequence([
            .group([.fadeOut(withDuration: 0.25), .scale(to: obs.xScale * 1.2, duration: 0.25)]),
            .removeFromParent()
        ]))
    }

    private func takeHit(from obs: ObstacleNode) {
        obs.scored = true
        obs.removeFromParent()
        loseLife(reason: "OUCH!")
    }

    // MARK: - Collectibles

    private func spawnCollectible() {
        let kind = CollectibleKind.weightedRandom()
        let node = CollectibleNode(kind: kind)
        let y = CGFloat.random(in: size.height * 0.34 ... roamYMax)
        let x = CGFloat.random(in: sideMargin + 24 ... size.width - sideMargin - 24)
        node.position = CGPoint(x: x, y: y)
        // mild perspective sizing
        let p = (spawnY - y) / (spawnY - nearPlaneY)
        node.setScale(max(0.7, 1.05 - 0.4 * p))
        node.zPosition = Z.obstacle - 0.5
        node.alpha = 0
        node.run(.fadeIn(withDuration: 0.3))
        playfield.addChild(node)
        collectibles.append(node)
    }

    private func updateCollectibles(_ dt: TimeInterval) {
        for c in collectibles where c.parent != nil && !c.collected {
            c.life -= dt
            if dist(c.position, player.position) < c.pickupRadius && !isSheltering {
                collect(c)
            } else if c.life <= 0 {
                c.collected = true
                c.run(.sequence([.group([.moveBy(x: 0, y: 40, duration: 0.5),
                                         .fadeOut(withDuration: 0.5)]), .removeFromParent()]))
            }
        }
        collectibles.removeAll { $0.parent == nil }
    }

    private func collect(_ c: CollectibleNode) {
        c.collected = true
        let value = c.kind.value
        addCoins(value)
        if c.kind == .gem { Haptics.shared.destroy() } else { Haptics.shared.coin() }
        floatingText("+\(value)", at: c.position, color: c.kind.tint, big: c.kind == .gem)
        burst(at: c.position, color: c.kind.tint)
        c.run(.sequence([.group([.scale(to: c.xScale * 1.8, duration: 0.2),
                                 .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
    }

    // MARK: - Projectiles

    private func updateProjectiles(_ dt: TimeInterval) {
        let speed: CGFloat = 780
        for bolt in projectiles where bolt.parent != nil {
            bolt.position.y += speed * CGFloat(dt)

            if let target = obstacles.first(where: {
                $0.parent != nil && !$0.scored &&
                abs($0.position.x - bolt.position.x) < 30 * $0.xScale + 14 &&
                abs($0.position.y - bolt.position.y) < 30 * $0.xScale + 16
            }) {
                bolt.removeFromParent()
                if let ch = target.letter {
                    target.scored = true
                    handleLetterShot(ch, at: target.position)
                    target.removeFromParent()
                } else if target.takeHit() {
                    // plain hazard destroyed
                    target.scored = true
                    let reward = target.kind.coinReward + 1
                    addCoins(reward)
                    Haptics.shared.destroy()
                    floatingText("+\(reward)", at: target.position, color: Palette.projectile)
                    burst(at: target.position, color: target.kind == .ball ? Palette.ball : Palette.boulder)
                    target.removeFromParent()
                } else {
                    Haptics.shared.land()
                }
                continue
            }

            if bolt.position.y > size.height + 30 { bolt.removeFromParent() }
        }
        projectiles.removeAll { $0.parent == nil }
    }

    // MARK: - Spelling logic

    private func handleLetterShot(_ ch: Character, at pos: CGPoint) {
        guard !isCelebratingWord, spelledIndex < currentWord.count else {
            // word already done / transitioning — just a fizzle
            burst(at: pos, color: Palette.boulder)
            return
        }
        if ch == currentWord[spelledIndex] {
            // CORRECT
            let lockedAt = spelledIndex
            spelledIndex += 1
            wordSlots.popLocked(lockedAt)
            wordSlots.lock(upTo: spelledIndex)
            addCoins(5)
            Haptics.shared.destroy()
            floatingText("\(ch) ✓", at: pos, color: SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1))
            burst(at: pos, color: SKColor(red: 0.4, green: 0.85, blue: 0.4, alpha: 1))
            if mode == .boss, let boss, !boss.isDefeated {
                if boss.takeHit(1) { defeatBoss(); return }
            }
            if spelledIndex >= currentWord.count { completeWord() }
        } else {
            // WRONG — gentle: no progress, just a buzz
            mistakes += 1
            wordSlots.shakeNext(spelledIndex)
            Haptics.shared.land()
            floatingText("✗ \(ch)", at: pos, color: Palette.warning)
            burst(at: pos, color: Palette.boulder)
        }
    }

    private func completeWord() {
        isCelebratingWord = true
        wordsCompleted += 1
        let entry = currentEntry
        graceTimer = max(graceTimer, 1.6)   // protect the duck during the cheer

        celebrateWord(entry) { [weak self] in
            guard let self else { return }
            switch self.mode {
            case .word:
                self.winLevel()
            case .streak:
                self.streakLabel.text = "✓ \(self.wordsCompleted)"
                self.addCoins(20)
                self.isCelebratingWord = false
                self.loadWord(WordBank.randomWord(forLevel: self.config.level,
                                                  avoiding: entry?.word))
            case .boss:
                self.addCoins(10)
                self.isCelebratingWord = false
                if self.boss?.isDefeated == true { return }
                self.loadWord(WordBank.randomWord(forLevel: self.config.level,
                                                  avoiding: entry?.word))
            }
        }
    }

    private func celebrateWord(_ entry: WordEntry?, then: @escaping () -> Void) {
        Haptics.shared.levelClear()
        let node = SKNode()
        node.position = CGPoint(x: size.width / 2, y: size.height * 0.46)
        node.zPosition = Z.overlay
        overlayLayer.addChild(node)

        let wordLbl = SKLabelNode(fontNamed: FontName.heavy)
        wordLbl.text = entry?.word ?? ""
        wordLbl.fontSize = 52
        wordLbl.fontColor = SKColor(red: 0.36, green: 0.78, blue: 0.36, alpha: 1)
        wordLbl.verticalAlignmentMode = .center
        node.addChild(wordLbl)

        let emoji = SKLabelNode(fontNamed: FontName.heavy)
        emoji.text = entry?.emoji ?? "⭐"
        emoji.fontSize = 64
        emoji.position = CGPoint(x: 0, y: 64)
        emoji.verticalAlignmentMode = .center
        node.addChild(emoji)

        // confetti
        for _ in 0..<18 {
            let c = SKShapeNode(rectOf: CGSize(width: 8, height: 8), cornerRadius: 2)
            c.fillColor = [Palette.coin, Palette.ball, Palette.projectile,
                           SKColor(red: 0.4, green: 0.85, blue: 0.4, alpha: 1)].randomElement()!
            c.strokeColor = .clear
            c.position = .zero
            node.addChild(c)
            let ang = CGFloat.random(in: 0...(2 * .pi))
            let d = CGFloat.random(in: 60...160)
            c.run(.sequence([.group([.moveBy(x: cos(ang) * d, y: sin(ang) * d, duration: 0.7),
                                     .rotate(byAngle: .pi * 2, duration: 0.7),
                                     .fadeOut(withDuration: 0.7)]), .removeFromParent()]))
        }

        node.setScale(0.4)
        let show = mode == .word ? 1.1 : 0.7
        node.run(.sequence([
            .scale(to: 1.0, duration: 0.2),
            .wait(forDuration: show),
            .group([.scale(to: 0.6, duration: 0.2), .fadeOut(withDuration: 0.2)]),
            .removeFromParent()
        ])) { then() }
    }

    // MARK: - Earthquake

    private func updateEarthquake(_ dt: TimeInterval) {
        quakeTimer -= dt
        switch quakePhase {
        case .calm:
            if quakeTimer <= config.quakeWarning { beginWarning() }
        case .warning:
            let intensity = CGFloat(1 - max(0, quakeTimer) / config.quakeWarning)
            redOverlay.alpha = 0.10 + 0.22 * intensity * (0.6 + 0.4 * CGFloat(abs(sin(elapsed * 12))))
            if quakeTimer <= 0 { strikeQuake() }
        }
    }

    private func beginWarning() {
        quakePhase = .warning
        Haptics.shared.warning()
        hut.setWarning(active: true)
        warningBanner.run(.fadeAlpha(to: 1.0, duration: 0.2))
        warningBanner.run(.repeatForever(.sequence([
            .scale(to: 1.05, duration: 0.3), .scale(to: 1.0, duration: 0.3)])), withKey: "pulse")
    }

    private func strikeQuake() {
        let safeCenter = CGPoint(x: hut.position.x + hut.doorOffset.x,
                                 y: hut.position.y + hut.doorOffset.y)
        let safe = dist(player.position, safeCenter) < hut.safeRadius
        shakeScreen()

        if safe {
            floatingText("SAFE!", at: CGPoint(x: hut.position.x, y: hut.position.y + 90),
                         color: Palette.coin, big: true)
            enterHut(door: safeCenter)
        } else {
            spawnGroundCrack(at: player.position)
            loseLife(reason: "SWALLOWED!")
        }

        quakePhase = .calm
        quakeTimer = config.quakeInterval
        hut.setWarning(active: false)
        warningBanner.removeAction(forKey: "pulse")
        warningBanner.run(.fadeAlpha(to: 0.0, duration: 0.25))
        redOverlay.run(.fadeAlpha(to: 0.0, duration: 0.3))
    }

    /// Run the duck into the cottage doorway, then pop back out.
    private func enterHut(door: CGPoint) {
        isSheltering = true
        duckTouch = nil
        player.removeAction(forKey: "invuln")
        player.zPosition = Z.hut - 1   // slip behind the hut front
        let inDoor = SKAction.group([
            .move(to: CGPoint(x: door.x, y: door.y + 6), duration: 0.22),
            .scale(to: 0.35, duration: 0.22),
            .fadeAlpha(to: 0.0, duration: 0.22)])
        inDoor.timingMode = .easeIn
        player.run(.sequence([inDoor, .wait(forDuration: 0.45)])) { [weak self] in
            guard let self else { return }
            let out = CGPoint(x: door.x, y: door.y + 36)
            self.player.zPosition = Z.player
            let popOut = SKAction.group([
                .move(to: out, duration: 0.22),
                .scale(to: 1.0, duration: 0.22),
                .fadeAlpha(to: 1.0, duration: 0.22)])
            popOut.timingMode = .easeOut
            self.player.run(popOut) {
                self.isSheltering = false
                self.duckTarget = out
            }
        }
    }

    private func spawnGroundCrack(at point: CGPoint) {
        let crack = SKShapeNode(path: crackPath())
        crack.fillColor = Palette.ink
        crack.strokeColor = Palette.warning
        crack.lineWidth = 2
        crack.position = CGPoint(x: point.x, y: point.y - 6)
        crack.zPosition = Z.player - 1
        crack.setScale(0.2)
        playfield.addChild(crack)
        crack.run(.sequence([.scale(to: 1.0, duration: 0.18), .wait(forDuration: 0.7),
                             .fadeOut(withDuration: 0.4), .removeFromParent()]))
    }

    private func crackPath() -> CGPath {
        let pts: [CGPoint] = [
            CGPoint(x: -46, y: 6), CGPoint(x: -18, y: -2), CGPoint(x: -26, y: -16),
            CGPoint(x: 4, y: -4), CGPoint(x: -4, y: -22), CGPoint(x: 30, y: -6),
            CGPoint(x: 22, y: 4), CGPoint(x: 48, y: 0), CGPoint(x: 24, y: 12),
            CGPoint(x: 30, y: 22), CGPoint(x: 2, y: 12), CGPoint(x: 8, y: 26),
            CGPoint(x: -16, y: 12), CGPoint(x: -22, y: 22), CGPoint(x: -30, y: 10)
        ]
        let p = CGMutablePath(); p.addLines(between: pts); p.closeSubpath()
        return p
    }

    // MARK: - Progress / win-loss

    private func updateProgress(_ dt: TimeInterval) {
        elapsed += dt
        switch mode {
        case .word, .boss:
            break   // won by completing the word / defeating the boss
        case .streak:
            let frac = min(1.0, CGFloat(elapsed / config.duration))
            progressFill.xScale = max(0.001, frac)
            if elapsed >= config.duration { winLevel() }
        }
    }

    private func defeatBoss() {
        guard let boss else { return }
        boss.playDefeat()
        floatingText("KNOCKOUT!", at: boss.position, color: Palette.coin, big: true)
        winLevel()
    }

    private func loseLife(reason: String) {
        guard isRunning else { return }
        lives -= 1
        updateLivesLabel()
        player.flashDamage()
        flashScreen(.white, alpha: 0.5)
        floatingText(reason, at: CGPoint(x: player.position.x, y: player.position.y + 60),
                     color: Palette.warning)
        shakeScreen(intensity: 9, count: 5)
        if lives <= 0 { gameOver() } else { Haptics.shared.hit() }
    }

    private func winLevel() {
        guard isRunning else { return }
        isRunning = false
        Haptics.shared.levelClear()
        let bonus = config.clearBonus
        addCoins(bonus)
        state.levelCleared(config.level)
        player.celebrate()

        let isFinal = config.level >= LevelConfig.maxLevel
        let sub: String
        switch mode {
        case .streak: sub = "\(wordsCompleted) words spelled • \(mistakes) misses"
        case .boss:   sub = isFinal ? "Spelled the boss into the ground!" : "Boss down!"
        case .word:   sub = "Spelled \(currentEntry?.word ?? "") • \(mistakes) misses"
        }
        let panel = makeResultPanel(
            title: isFinal ? "YOU WON!" : "LEVEL \(config.level) CLEAR!",
            subtitle: sub,
            coins: runCoins)
        overlayLayer.addChild(panel)
        let primary = isFinal ? "FINISH" : "NEXT"
        addPanelButton(to: panel, text: primary, yOffset: -90, color: Palette.coin) { [weak self] in
            self?.proceedAfterWin(isFinal: isFinal)
        }
        addPanelButton(to: panel, text: "MENU", yOffset: -156, color: Palette.projectile) { [weak self] in
            self?.quitToMenu()
        }
    }

    private func proceedAfterWin(isFinal: Bool) {
        if isFinal { quitToMenu(); return }
        let next = min(config.level + 1, LevelConfig.maxLevel)
        let shop = UpgradeScene(size: size)
        shop.scaleMode = scaleMode
        shop.returnLevel = next
        shop.continueToNextLevel = true
        view?.presentScene(shop, transition: .doorway(withDuration: 0.5))
    }

    private func gameOver() {
        isRunning = false
        Haptics.shared.gameOver()
        let panel = makeResultPanel(title: "GAME OVER",
                                    subtitle: config.isBoss ? "The boss stands tall." : "The hill got you.",
                                    coins: runCoins)
        overlayLayer.addChild(panel)
        addPanelButton(to: panel, text: "RETRY", yOffset: -90, color: Palette.coin) { [weak self] in
            self?.retry()
        }
        addPanelButton(to: panel, text: "MENU", yOffset: -156, color: Palette.projectile) { [weak self] in
            self?.quitToMenu()
        }
    }

    private func retry() {
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .fade(withDuration: 0.4))
    }

    private func quitToMenu() {
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .fade(withDuration: 0.4))
    }

    // MARK: - HUD helpers

    private func addCoins(_ amount: Int) {
        runCoins += amount
        state.addCoins(amount)
        coinLabel.text = "\(state.coins)"
        coinLabel.run(.sequence([.scale(to: 1.25, duration: 0.07), .scale(to: 1.0, duration: 0.07)]))
        if elapsed - lastCoinHaptic > 0.12 {
            lastCoinHaptic = elapsed
            Haptics.shared.coin()
        }
    }

    private func flashScreen(_ color: SKColor, alpha: CGFloat) {
        let flash = SKSpriteNode(color: color, size: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = Z.effects + 1
        flash.alpha = alpha
        addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.22), .removeFromParent()]))
    }

    private func updateLivesLabel() {
        livesLabel.text = lives > 0 ? String(repeating: "♥", count: lives) : "—"
    }

    private func floatingText(_ text: String, at point: CGPoint, color: SKColor, big: Bool = false) {
        let lbl = SKLabelNode(fontNamed: FontName.heavy)
        lbl.text = text
        lbl.fontSize = big ? 40 : 22
        lbl.fontColor = color
        lbl.position = point
        lbl.zPosition = Z.overlay
        playfield.addChild(lbl)
        lbl.run(.sequence([.group([.moveBy(x: 0, y: 46, duration: 0.7), .fadeOut(withDuration: 0.7)]),
                           .removeFromParent()]))
    }

    private func burst(at point: CGPoint, color: SKColor) {
        for _ in 0..<8 {
            let shard = SKShapeNode(rectOf: CGSize(width: 6, height: 6), cornerRadius: 1.5)
            shard.fillColor = color
            shard.strokeColor = .clear
            shard.position = point
            shard.zPosition = Z.effects
            playfield.addChild(shard)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let d = CGFloat.random(in: 20...60)
            shard.run(.sequence([
                .group([.moveBy(x: cos(angle) * d, y: sin(angle) * d, duration: 0.35),
                        .fadeOut(withDuration: 0.35)]),
                .removeFromParent()]))
        }
    }

    private func shakeScreen(intensity: CGFloat = 10, count: Int = 6) {
        var seq: [SKAction] = []
        for _ in 0..<count {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            seq.append(.moveBy(x: dx, y: dy, duration: 0.03))
            seq.append(.moveBy(x: -dx, y: -dy, duration: 0.03))
        }
        seq.append(.move(to: .zero, duration: 0.03))
        playfield.run(.sequence(seq))
    }

    // MARK: - Result panel builders

    private func makeResultPanel(title: String, subtitle: String, coins: Int) -> SKNode {
        let container = SKNode()
        let dim = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.45), size: size)
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(dim)

        let card = SKShapeNode(rectOf: CGSize(width: size.width * 0.82, height: 360), cornerRadius: 24)
        card.fillColor = Palette.panel
        card.strokeColor = .white
        card.lineWidth = 2
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.addChild(card)

        let t = SKLabelNode(fontNamed: FontName.heavy)
        t.text = title; t.fontSize = 36; t.fontColor = .white
        t.position = CGPoint(x: 0, y: 110); card.addChild(t)

        let s = SKLabelNode(fontNamed: FontName.demi)
        s.text = subtitle; s.fontSize = 16; s.fontColor = SKColor.white.withAlphaComponent(0.85)
        s.position = CGPoint(x: 0, y: 74); card.addChild(s)

        let earned = SKLabelNode(fontNamed: FontName.bold)
        earned.text = "Coins this run: \(coins)"; earned.fontSize = 20; earned.fontColor = Palette.coin
        earned.position = CGPoint(x: 0, y: 30); card.addChild(earned)

        container.alpha = 0
        container.run(.fadeIn(withDuration: 0.3))
        return container
    }

    private func addPanelButton(to panel: SKNode, text: String, yOffset: CGFloat,
                                color: SKColor, action: @escaping () -> Void) {
        let button = ButtonNode(text: text, color: color)
        button.position = CGPoint(x: size.width / 2, y: size.height / 2 + yOffset)
        button.onTap = action
        panel.addChild(button)
        panelButtons.append(button)
    }
}
