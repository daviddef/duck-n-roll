//
//  Color+Extensions.swift
//  Duck-n-Roll
//
//  Tiny helpers for deriving shade variants used by the procedural art.
//

import SpriteKit

extension SKColor {
    func adjust(by amount: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: max(0, min(1, r + amount)),
                       green: max(0, min(1, g + amount)),
                       blue: max(0, min(1, b + amount)),
                       alpha: a)
    }
    func darker(_ amount: CGFloat = 0.18) -> SKColor { adjust(by: -amount) }
    func lighter(_ amount: CGFloat = 0.18) -> SKColor { adjust(by: amount) }
}
