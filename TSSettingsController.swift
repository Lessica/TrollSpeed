import UIKit

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
        return 7;
    }
    
    open override func settingTitle(index: Int, highlighted: Bool) -> String {
        if index == 0 {
            return NSLocalizedString("Pass-through", comment: "")
        } else if index == 1 {
            return NSLocalizedString("Keep In-place", comment: "")
        } else if index == 2 {
            return NSLocalizedString("Incoming Only", comment: "")
        } else if index == 3 {
            return NSLocalizedString("Landscape", comment: "")
        } else if index == 4 {
            return NSLocalizedString("Size", comment: "")
        } else if index == 5 {
            return NSLocalizedString("Unit", comment: "")
        } else {
            return NSLocalizedString("Prefixes", comment: "")
        }
    }
    
    open override func settingSubtitle(index: Int, highlighted: Bool) -> String? {
        if index == 0 {
            if restartRequired {
                return NSLocalizedString("Re-open to apply", comment: "")
            } else {
                if (highlighted) {
                    return NSLocalizedString("ON", comment: "")
                } else {
                    return NSLocalizedString("OFF", comment: "")
                }
            }
        } else if index == 1 || index == 2 {
            if (highlighted) {
                return NSLocalizedString("ON", comment: "")
            } else {
                return NSLocalizedString("OFF", comment: "")
            }
        } else if index == 3 {
            if (highlighted) {
                return NSLocalizedString("Follow", comment: "")
            } else {
                return NSLocalizedString("Hide", comment: "")
            }
        } else if index == 4 {
            if (highlighted) {
                return NSLocalizedString("Large", comment: "")
            } else {
                return NSLocalizedString("Standard", comment: "")
            }
        } else if index == 5 {
            if (highlighted) {
                return NSLocalizedString("b/s", comment: "")
            } else {
                return NSLocalizedString("B/s", comment: "")
            }
        } else {
            if (highlighted) {
                return NSLocalizedString("↑↓", comment: "")
            } else {
                return NSLocalizedString("▲▼", comment: "")
            }
        }
    }

    private func settingKey(index: Int) -> String {
        if index == 0 {
            return "passthroughMode"
        } else if index == 1 {
            return "keepInPlace"
        } else if index == 2 {
            return "singleLineMode"
        } else if index == 3 {
            return "usesRotation"
        } else if index == 4 {
            return "usesLargeFont"
        } else if index == 5 {
            return "usesBitrate"
        } else {
            return "usesArrowPrefixes"
        }
    }
    
    open override func settingHighlighted(index: Int) -> Bool {
        return delegate?.settingHighlighted(key: settingKey(index: index)) ?? false
    }
    
    open override func settingColorHighlighted(index: Int) -> UIColor {
        // rgba(22, 160, 133, 1.0)
        return UIColor(red: 22.0/255.0, green: 160.0/255.0, blue: 133.0/255.0, alpha: 1.0)
    }
    
    open override func settingDidSelect(index: Int, completion: @escaping () -> ()) {
        if index == 0 && alreadyLaunched {
            restartRequired = true
        }
        delegate?.settingDidSelect(key: settingKey(index: index))
        completion()
    }
}