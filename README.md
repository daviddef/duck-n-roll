# Duck Evolution 🦆

A native iOS arcade dodger built with **Swift + SpriteKit**. You play a duckling
that **evolves a new form every few levels** while rolling boulders and bouncing
balls hurtle down a hill toward you. Dodge, hop, or shoot them — and sprint to
your **hut** whenever an **earthquake** is about to rip the ground open. Survive
30 levels to face the **boss** in a final punch-up.

This is the **playable vertical slice**: the full core loop is implemented and the
difficulty/evolution data already scales across all 30 levels + the boss.

---

## Requirements

- **Xcode 16 or newer** (the project uses Xcode 16 "synchronized" folder groups, so
  every `.swift` file under `Duck-n-Roll/` is included automatically — no manual
  file management).
- iOS 16+ device or Simulator.
- No third-party dependencies, **no image/audio assets** — all art is drawn
  procedurally from shapes, so it builds and runs out of the box.

## Run it

1. Open `Duck-n-Roll.xcodeproj` in Xcode.
2. Select an iPhone simulator (e.g. iPhone 15) or your device.
3. Press **Run** (⌘R).

If you run on a physical device, set your signing **Team** under
*Target → Signing & Capabilities* (the bundle id is `com.mateo.Duck-n-Roll`).

---

## How to play

| Control | Action |
|---|---|
| **Drag** anywhere | Pan the duck left / right to dodge |
| **JUMP** button | Hop over **boulders** (does *not* clear bouncing balls) |
| **SHOOT** button | Fire a bolt to destroy obstacles (unlocks at level 3) |
| Reach the **hut** | Stand in the glowing safe zone before the quake hits |

- **Boulders** are heavy and low — *jump* them or shoot them (2 hits).
- **Balls** are fast and bouncy — *dodge* or shoot them (1 hit). Can't be jumped.
- **Earthquakes**: a red banner warns you. When it strikes, if you're not in the
  hut's safe zone you get swallowed and lose a life.
- **Coins** are earned for every obstacle survived (more for shooting), plus a
  clear bonus each level. Spend them in the **Upgrade Shop** on permanent
  **Speed** and **Jump** boosts between levels.
- **3 lives.** Lose them all → Game Over. Clear level 30's boss → you win.

---

## Project layout

```
Duck-n-Roll/
├── App/
│   ├── AppDelegate.swift          # window + lifecycle (no storyboard)
│   └── GameViewController.swift   # hosts the SKView, presents MenuScene
├── Model/
│   ├── GameState.swift            # coins, lives, progress, upgrades (UserDefaults)
│   ├── LevelConfig.swift          # data-driven difficulty for levels 1...30 + boss
│   └── EvolutionStage.swift       # the 6 evolution forms, mapped to levels
├── Entities/
│   ├── PlayerNode.swift           # the duck (procedural, restyles per evolution)
│   ├── ObstacleNode.swift         # boulders & balls + perspective scaling
│   ├── HutNode.swift              # home base / earthquake safe zone
│   ├── ProjectileNode.swift       # the shot
│   └── BossNode.swift             # level-30 boss with health bar
├── Scenes/
│   ├── MenuScene.swift            # title, evolution preview, level chooser
│   ├── GameScene.swift            # the core gameplay loop
│   └── UpgradeScene.swift         # the upgrade shop
└── Support/
    ├── Theme.swift                # colors, fonts, z-order, physics categories
    ├── Backdrop.swift             # shared sky + hill scenery
    ├── ButtonNode.swift           # reusable tappable button
    └── Color+Extensions.swift     # shade helpers for the procedural art
```

## Tuning the game

Almost all balancing lives in two files:

- **`LevelConfig.swift`** — spawn rate, obstacle speed, ball vs boulder ratio,
  level duration, earthquake frequency/warning, and clear bonus are all derived
  from smooth curves keyed off the level number. Tweak the constants in
  `config(for:)` to rebalance the entire game at once.
- **`EvolutionStage.swift`** — the forms the character takes and which level each
  one appears at.

## What's stubbed for later (next passes)

The slice is fully playable; these are the natural extensions toward the complete
30-level vision:

- More **weapons & power-ups** per level (rapid-fire, spread shot, shield, magnet).
  The `LevelConfig` already has a `shootingUnlocked` flag as the pattern to follow.
- A richer **boss fight** (multiple attack patterns / phases) — `BossNode` is a
  working foundation with a health bar and defeat sequence.
- Art/audio polish: swap the procedural shapes for sprite art and add SFX/music.
- Hand-authored level layouts instead of (or alongside) the procedural curves.
