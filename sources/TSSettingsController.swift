//
//  TSSettingsController.swift
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

import UIKit

private enum TSSettingsIndex: Int, CaseIterable {
    case passthroughMode = 0
    case keepInPlace
    case hideAtSnapshot
    case singleLineMode
    case usesRotation
    case usesLargeFont
    case usesBitrate
    case usesArrowPrefixes
    case usesInvertedColor

    var key: String {
        switch self {
        case .passthroughMode:
            return "passthroughMode"
        case .keepInPlace:
            return "keepInPlace"
        case .hideAtSnapshot:
            return "hideAtSnapshot"
        case .singleLineMode:
            return "singleLineMode"
        case .usesRotation:
            return "usesRotation"
        case .usesLargeFont:
            return "usesLargeFont"
        case .usesBitrate:
            return "usesBitrate"
        case .usesArrowPrefixes:
            return "usesArrowPrefixes"
        case .usesInvertedColor:
            return "usesInvertedColor"
        }
    }

    var title: String {
        switch self {
        case .passthroughMode:
            return NSLocalizedString("Pass-through", comment: "")
        case .keepInPlace:
            return NSLocalizedString("Keep In-place", comment: "")
        case .hideAtSnapshot:
            return NSLocalizedString("Hide @snapshot", comment: "")
        case .singleLineMode:
            return NSLocalizedString("Incoming Only", comment: "")
        case .usesRotation:
            return NSLocalizedString("Landscape", comment: "")
        case .usesLargeFont:
            return NSLocalizedString("Size", comment: "")
        case .usesBitrate:
            return NSLocalizedString("Unit", comment: "")
        case .usesArrowPrefixes:
            return NSLocalizedString("Prefixes", comment: "")
        case .usesInvertedColor:
            return NSLocalizedString("Appearance", comment: "")
        }
    }

    func subtitle(highlighted: Bool, restartRequired: Bool) -> String {
        switch self {
        case .passthroughMode:
            if restartRequired {
                return NSLocalizedString("Re-open to apply", comment: "")
            } else {
                return highlighted ? NSLocalizedString("ON", comment: "") : NSLocalizedString("OFF", comment: "")
            }
        case .keepInPlace: fallthrough
        case .hideAtSnapshot: fallthrough
        case .singleLineMode:
            return highlighted ? NSLocalizedString("ON", comment: "") : NSLocalizedString("OFF", comment: "")
        case .usesRotation:
            return highlighted ? NSLocalizedString("Follow", comment: "") : NSLocalizedString("Hide", comment: "")
        case .usesLargeFont:
            return highlighted ? NSLocalizedString("Large", comment: "") : NSLocalizedString("Standard", comment: "")
        case .usesBitrate:
            return highlighted ? NSLocalizedString("b/s", comment: "") : NSLocalizedString("B/s", comment: "")
        case .usesArrowPrefixes:
            return highlighted ? NSLocalizedString("↑↓", comment: "") : NSLocalizedString("▲▼", comment: "")
        case .usesInvertedColor:
            return highlighted ? NSLocalizedString("Inverted", comment: "") : NSLocalizedString("Classic", comment: "")
        }
    }
}

@objc public protocol TSSettingsControllerDelegate {
    func settingHighlighted(key: String) -> Bool
    func settingDidSelect(key: String) -> Void
}

@objc open class TSSettingsController : SPLarkSettingsController
{
    @objc open weak var delegate: TSSettingsControllerDelegate?
    @objc open var alreadyLaunched: Bool = false
    internal var restartRequired = false

    open override func settingsCount() -> Int {
        return TSSettingsIndex.allCases.count
    }

    open override func settingTitle(index: Int, highlighted: Bool) -> String {
        return TSSettingsIndex.allCases[index].title
    }

    open override func settingSubtitle(index: Int, highlighted: Bool) -> String? {
        return TSSettingsIndex.allCases[index].subtitle(highlighted: highlighted, restartRequired: restartRequired)
    }

    private func settingKey(index: Int) -> String {
        return TSSettingsIndex.allCases[index].key
    }

    open override func settingHighlighted(index: Int) -> Bool {
        return delegate?.settingHighlighted(key: settingKey(index: index)) ?? false
    }

    open override func settingColorHighlighted(index: Int) -> UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 28/255.0, green: 74/255.0, blue: 82/255.0, alpha: 1.0)
            } else {
                return UIColor(red: 22/255.0, green: 160/255.0, blue: 133/255.0, alpha: 1.0)
            }
        }
    }

    open override func settingDidSelect(index: Int, completion: @escaping () -> ()) {
        if index == 0 && alreadyLaunched {
            restartRequired = true
        }
        delegate?.settingDidSelect(key: settingKey(index: index))
        completion()
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard let currentOrientation = view.window?.windowScene?.interfaceOrientation else {
            return [.portrait]
        }
        switch currentOrientation {
        case .unknown: fallthrough
        case .portrait:
            return [.portrait]
        case .portraitUpsideDown:
            return [.portraitUpsideDown]
        case .landscapeLeft:
            return [.landscapeLeft]
        case .landscapeRight:
            return [.landscapeRight]
        @unknown default:
            return [.portrait]
        }
    }

    open override var shouldAutorotate: Bool { false }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != self.traitCollection.userInterfaceStyle {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
