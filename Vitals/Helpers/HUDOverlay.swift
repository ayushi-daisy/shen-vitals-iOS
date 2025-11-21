//
//  HUDOverlay.swift
//  Vitals
//
//  Created by Ayushi on 2025-10-27.
//

import UIKit

enum HUDOverlay {
    private static var blocker: UIView?
    private static var hud: UIVisualEffectView?

    @MainActor
    static func show(_ text: String, dimAlpha: CGFloat = 0.05) {
        
        guard blocker == nil, hud == nil, let win = AppDelegate.shared.window else { return }

            
        // Fullscreen touch blocker on the app window
        let blocker = UIView(frame: win.bounds)
//        blocker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blocker.backgroundColor = dimAlpha > 0 ? UIColor.black.withAlphaComponent(dimAlpha) : .clear
        blocker.isUserInteractionEnabled = true            // intercept all touches
        win.addSubview(blocker)                            // sits above nav/status since it's on the window
        self.blocker = blocker

        // Centered blur HUD
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        blur.layer.cornerRadius = 16
        blur.layer.masksToBounds = true
        blur.translatesAutoresizingMaskIntoConstraints = false

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        blur.contentView.addSubview(stack)
        blocker.addSubview(blur)

        NSLayoutConstraint.activate([
            blur.centerXAnchor.constraint(equalTo: blocker.centerXAnchor),
            blur.centerYAnchor.constraint(equalTo: blocker.centerYAnchor),
            blur.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),

            stack.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -20),
        ])

        self.hud = blur
    }

    @MainActor
    static func hide() {
        hud?.removeFromSuperview()
        hud = nil
        blocker?.removeFromSuperview()
        blocker = nil
    }
}
