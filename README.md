# Duck 'n' Roll 🦆📚

A native iOS **educational spelling arcade** built with **Swift + SpriteKit**. You
play a duckling rolling down a hill where boulders tumble toward you wearing
**letters** — shoot them **in the right order to spell the target word**, dodge
the balls, dash home before earthquakes, and **evolve** a new form every few
levels. Get the word right → next level.

The whole game is drawn **procedurally** (gradient-shaded sprites, parallax
mountains, candy UI) in a storybook-painterly style, so it ships with **no image
or audio asset files** and builds straight out of the box.

---

## How it plays

You spell a word by **shooting lettered boulders in order**:

- The **target word** sits at the top as letter tiles, with the **next letter you
  need glowing** so a young player always knows what to hunt for.
- Boulders roll down **wearing letters** (clear, upright badges). **Shoot the one
  that matches your current slot** → it locks in green with a pop.
- Shoot any **wrong letter** → a gentle buzz, **no progress** (mistakes are just
  tallied, never punished — kid-friendly).
- Finish the word → a celebration (the word + its emoji, e.g. `CAT 🐱`) → **next
  level**.

**Lettered boulders are friendly targets — they never hurt you.** The danger
comes from **balls, plain rocks, and earthquakes**, so a learner focused on
reading and aiming isn't getting squashed by the thing they're trying to spell.

### Controls

| Input | Action |
|---|---|
| **Drag** | Run the duck around — left/right *and* up the hill |
| **Tap** | Hop (a quick squash-and-stretch jump) |
| **Floating shoot icon** | Tap to fire a bolt; **drag it** to reposition it anywhere |

### The rest of the loop

- **Run up the hill** to grab **collectibles** — coins (+5), candy (+20), gems
  (+50) — at the risk of being up among the hazards and far from home.
- **Earthquakes**: a red banner warns you, then the duck must **run into the
  cottage** (bottom-left) before it strikes, or get swallowed and lose a life.
- **Evolution**: the character takes a new form every 5 levels (6 forms total).
- **Coins** fund the **Upgrade Shop** between levels — permanent **Speed** and
  **Jump** boosts.
- **3 lives.** Lose them all → Game Over (retry the level).
- **Haptics** throughout (jump, shoot, correct/wrong letter, coin, quake warning,
  level clear) — these fire on a real device, not the Simulator.

### Level types

| Levels | Mode | Goal |
|---|---|---|
| Regular | **Spell one word** | Complete the word to advance. Words scale 3→6 letters by tier. |
| **5, 10, 15, 20, 25** | **Streak round** | Spell as many words as you can before the timer runs out (these line up with the evolution milestones). |
| **30** | **Boss spell-off** | Every correct letter chips the boss's health down until it's defeated. |

Shooting is available from **level 1**, and the built-in word list (`WordBank`)
grows from `CAT / SUN / DOG` up through `DUCK / FROG`, `SNAIL / TIGER`, to
`RABBIT / DRAGON`.

---

## Requirements

- **Xcode 16 or newer** (the project uses Xcode 16 "synchronized" folder groups,
  so every `.swift` file under `Duck-n-Roll/` is included automatically).
- **iOS 16+**. Universal (iPhone + iPad), **portrait-only** (`UIRequiresFullScreen`).
- **No third-party dependencies**, no external art/audio — everything is rendered
  procedurally at runtime.

## Run it

1. Open `Duck-n-Roll.xcodeproj` in Xcode.
2. Pick an iPhone simulator (or your device) and press **Run** (⌘R).
3. To jump straight into a specific level for testing, pass the launch argument
   `-startLevel N` (Scheme → Run → Arguments). Handy for the boss (`-startLevel 30`)
   or a streak round (`-startLevel 5`).

For a device/TestFlight build, set your signing **Team** under
*Target → Signing & Capabilities*.

---

## Project layout

```
Duck-n-Roll/
├── App/
│   ├── AppDelegate.swift          # window + lifecycle (no storyboard / scenes)
│   └── GameViewController.swift   # hosts the SKView, presents MenuScene
├── Model/
│   ├── GameState.swift            # coins, progress, upgrades (UserDefaults)
│   ├── LevelConfig.swift          # data-driven difficulty + level mode (word/streak/boss)
│   ├── EvolutionStage.swift       # the 6 evolution forms, mapped to levels
│   └── WordBank.swift             # built-in spelling words, tiered 3→6 letters + emoji
├── Entities/
│   ├── PlayerNode.swift           # the duck (procedural, restyles per evolution)
│   ├── ObstacleNode.swift         # boulders & balls; boulders carry letters
│   ├── CollectibleNode.swift      # coins / candy / gems up the hill
│   ├── HutNode.swift              # the cottage / earthquake shelter
│   ├── ProjectileNode.swift       # the bolt
│   └── BossNode.swift             # level-30 boss with health bar
├── Scenes/
│   ├── MenuScene.swift            # logo, word preview, level chooser
│   ├── GameScene.swift            # the core gameplay loop + spelling logic
│   └── UpgradeScene.swift         # the upgrade shop
├── Support/
│   ├── Theme.swift                # colors, fonts, z-order, physics categories
│   ├── TextureFactory.swift       # procedural shaded sprites (spheres, rock, mountains, UI)
│   ├── Backdrop.swift             # storybook sky + parallax mountains + hill
│   ├── WordSlotsNode.swift        # the target-word letter tiles (HUD)
│   ├── ButtonNode.swift           # reusable candy button
│   ├── Haptics.swift              # UIKit feedback wrapper
│   └── Color+Extensions.swift     # shade helpers for the procedural art
└── Assets.xcassets/              # AppIcon, AccentColor, Logo (procedurally generated PNGs)
```

## Tuning the game

Most balancing lives in three files:

- **`WordBank.swift`** — the spelling words, grouped into difficulty tiers. Swap in
  your own list (e.g. a child's sight words) here.
- **`LevelConfig.swift`** — spawn rate, obstacle speed, ball ratio, streak/boss
  duration, earthquake timing, and per-level **mode** are derived from smooth
  curves keyed off the level number. `GameScene` also exposes the needed-letter
  spawn frequency (`chooseLetter`) and collision tightness.
- **`EvolutionStage.swift`** — the forms the character takes and when they appear.

## Distribution notes

- Display name: **Duck 'n' Roll** · bundle id: `com.defranceski.Duck-n-Roll`
- Portrait-only universal app (`UIRequiresFullScreen = YES`) — opts out of iPad
  multitasking so it isn't required to support landscape.
- Declares **no non-exempt encryption** (`ITSAppUsesNonExemptEncryption = NO`), so
  the App Store encryption question is auto-answered.

## Natural next steps

- **Audio** — say each letter as it locks and the word on completion, plus SFX and
  music. This is the biggest remaining win for the educational side.
- Themed word packs (animals, food, colours) and a parent/teacher custom word list.
- Richer multi-phase boss, more power-ups, and hand-authored level layouts.
