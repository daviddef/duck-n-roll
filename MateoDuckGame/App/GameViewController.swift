//
//  GameViewController.swift
//  MateoDuckGame
//
//  Hosts the SpriteKit view and presents the first scene (the menu).
//

import UIKit
import SpriteKit

final class GameViewController: UIViewController {

    override func loadView() {
        // Use an SKView as the controller's root view.
        view = SKView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }
        skView.ignoresSiblingOrder = true
        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        #endif

        let scene = Self.makeInitialScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    /// Normally the menu. Pass `-startLevel N` as a launch argument to jump
    /// straight into level N (handy for testing a specific level or the boss).
    private static func makeInitialScene(size: CGSize) -> SKScene {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-startLevel"),
           i + 1 < args.count, let level = Int(args[i + 1]) {
            GameState.shared.currentLevel = max(1, min(level, LevelConfig.maxLevel))
            return GameScene(size: size)
        }
        return MenuScene(size: size)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
