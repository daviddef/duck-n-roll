//
//  Haptics.swift
//  Duck-n-Roll
//
//  Thin wrapper over UIKit's feedback generators. Generators are kept warm with
//  prepare() so the taps fire with minimal latency during play. No-ops on the
//  Simulator (no Taptic Engine) but works on device.
//

import UIKit

final class Haptics {

    static let shared = Haptics()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let notify = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    /// Master switch (could be wired to a settings toggle later).
    var enabled = true

    private init() {}

    /// Warm up the engine — call when a scene that uses haptics appears.
    func prepareAll() {
        guard enabled else { return }
        [light, medium, heavy, rigid, soft].forEach { $0.prepare() }
        notify.prepare()
        selection.prepare()
    }

    func jump()        { impact(light, intensity: 0.7) }
    func shoot()       { impact(rigid, intensity: 0.6) }
    func destroy()     { impact(medium, intensity: 0.9) }
    func coin()        { guard enabled else { return }; selection.selectionChanged(); selection.prepare() }
    func uiTap()       { guard enabled else { return }; selection.selectionChanged(); selection.prepare() }
    func hit()         { impact(heavy, intensity: 1.0) }
    func land()        { impact(soft, intensity: 0.5) }

    func warning()     { notification(.warning) }
    func levelClear()  { notification(.success) }
    func gameOver()    { notification(.error) }

    // MARK: - Internals

    private func impact(_ gen: UIImpactFeedbackGenerator, intensity: CGFloat) {
        guard enabled else { return }
        gen.impactOccurred(intensity: intensity)
        gen.prepare()
    }

    private func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        notify.notificationOccurred(type)
        notify.prepare()
    }
}
