//
//  TSSettingsIndex.swift
//  TrollSpeed
//
//  Created by Lessica on 2024/1/25.
//

import Foundation

enum TSSettingsIndex: Int, CaseIterable {
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
            return HUDUserDefaultsKeyPassthroughMode
        case .keepInPlace:
            return HUDUserDefaultsKeyKeepInPlace
        case .hideAtSnapshot:
            return HUDUserDefaultsKeyHideAtSnapshot
        case .singleLineMode:
            return HUDUserDefaultsKeySingleLineMode
        case .usesRotation:
            return HUDUserDefaultsKeyUsesRotation
        case .usesLargeFont:
            return HUDUserDefaultsKeyUsesLargeFont
        case .usesBitrate:
            return HUDUserDefaultsKeyUsesBitrate
        case .usesArrowPrefixes:
            return HUDUserDefaultsKeyUsesArrowPrefixes
        case .usesInvertedColor:
            return HUDUserDefaultsKeyUsesInvertedColor
        }
    }

    var title: String {
        switch self {
        case .passthroughMode:
            return NSLocalizedString("Pass-through", comment: "TSSettingsIndex")
        case .keepInPlace:
            return NSLocalizedString("Keep In-place", comment: "TSSettingsIndex")
        case .hideAtSnapshot:
            return NSLocalizedString("Hide @snapshot", comment: "TSSettingsIndex")
        case .singleLineMode:
            return NSLocalizedString("Incoming Only", comment: "TSSettingsIndex")
        case .usesRotation:
            return NSLocalizedString("Landscape", comment: "TSSettingsIndex")
        case .usesLargeFont:
            return NSLocalizedString("Size", comment: "TSSettingsIndex")
        case .usesBitrate:
            return NSLocalizedString("Unit", comment: "TSSettingsIndex")
        case .usesArrowPrefixes:
            return NSLocalizedString("Prefixes", comment: "TSSettingsIndex")
        case .usesInvertedColor:
            return NSLocalizedString("Appearance", comment: "TSSettingsIndex")
        }
    }

    func subtitle(highlighted: Bool, restartRequired: Bool) -> String {
        switch self {
        case .passthroughMode:
            if restartRequired {
                return NSLocalizedString("Re-open to apply", comment: "TSSettingsIndex")
            } else {
                return highlighted ? NSLocalizedString("ON", comment: "TSSettingsIndex") : NSLocalizedString("OFF", comment: "TSSettingsIndex")
            }
        case .keepInPlace: fallthrough
        case .hideAtSnapshot: fallthrough
        case .singleLineMode:
            return highlighted ? NSLocalizedString("ON", comment: "TSSettingsIndex") : NSLocalizedString("OFF", comment: "TSSettingsIndex")
        case .usesRotation:
            return highlighted ? NSLocalizedString("Follow", comment: "TSSettingsIndex") : NSLocalizedString("Hide", comment: "TSSettingsIndex")
        case .usesLargeFont:
            return highlighted ? NSLocalizedString("Large", comment: "TSSettingsIndex") : NSLocalizedString("Standard", comment: "TSSettingsIndex")
        case .usesBitrate:
            return highlighted ? NSLocalizedString("b/s", comment: "TSSettingsIndex") : NSLocalizedString("B/s", comment: "TSSettingsIndex")
        case .usesArrowPrefixes:
            return highlighted ? NSLocalizedString("↑↓", comment: "TSSettingsIndex") : NSLocalizedString("▲▼", comment: "TSSettingsIndex")
        case .usesInvertedColor:
            return highlighted ? NSLocalizedString("Inverted", comment: "TSSettingsIndex") : NSLocalizedString("Classic", comment: "TSSettingsIndex")
        }
    }
}
