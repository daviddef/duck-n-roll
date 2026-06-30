//
//  ButtonNode.swift
//  Duck-n-Roll
//
//  A glossy "candy" button (gradient face, 3D lip, drop shadow) used across the
//  menus and HUD. Tap handling is done by the owning scene via the `onTap`
//  closure or a `contains(parentPoint:)` hit-test.
//

import SpriteKit

final class ButtonNode: SKNode {

    var onTap: (() -> Void)?
    private let background = SKSpriteNode()
    private let label: SKLabelNode
    private let shadowLabel: SKLabelNode
    private let buttonSize: CGSize
    private var color: SKColor
    private(set) var isEnabledButton = true

    init(text: String,
         size: CGSize = CGSize(width: 230, height: 60),
         color: SKColor = Palette.projectile,
         fontSize: CGFloat = 24) {
        self.buttonSize = size
        self.color = color

        label = SKLabelNode(fontNamed: FontName.heavy)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1

        shadowLabel = SKLabelNode(fontNamed: FontName.heavy)
        shadowLabel.text = text
        shadowLabel.fontSize = fontSize
        shadowLabel.fontColor = SKColor.black.withAlphaComponent(0.28)
        shadowLabel.verticalAlignmentMode = .center
        shadowLabel.horizontalAlignmentMode = .center
        shadowLabel.position = CGPoint(x: 0, y: -2)
        shadowLabel.zPosition = 0.9

        super.init()
        isUserInteractionEnabled = false   // scene routes touches
        background.texture = texture(for: color)
        background.size = CGSize(width: size.width + 40, height: size.height + 40)
        addChild(background)
        addChild(shadowLabel)
        addChild(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func texture(for c: SKColor) -> SKTexture {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        let key = "\(Int(buttonSize.width))x\(Int(buttonSize.height))-\(Int(r*255))-\(Int(g*255))-\(Int(b*255))"
        return TextureFactory.button(width: buttonSize.width, height: buttonSize.height, color: c, key: key)
    }

    var text: String {
        get { label.text ?? "" }
        set {
            label.text = newValue
            shadowLabel.text = newValue
        }
    }

    func setColor(_ c: SKColor) {
        color = c
        background.texture = texture(for: c)
    }

    func setEnabled(_ enabled: Bool) {
        isEnabledButton = enabled
        alpha = enabled ? 1.0 : 0.45
    }

    func animatePress() {
        run(.sequence([.scale(to: 0.92, duration: 0.06), .scale(to: 1.0, duration: 0.09)]))
    }

    /// True if a point in the button's PARENT space falls within the button face.
    func contains(parentPoint: CGPoint) -> Bool {
        guard isEnabledButton else { return false }
        let local = CGPoint(x: parentPoint.x - position.x, y: parentPoint.y - position.y)
        let r = CGRect(x: -buttonSize.width / 2 - 6, y: -buttonSize.height / 2 - 6,
                       width: buttonSize.width + 12, height: buttonSize.height + 12)
        return r.contains(local)
    }
}
