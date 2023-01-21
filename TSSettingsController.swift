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
        return 4;
    }
    
    open override func settingTitle(index: Int, highlighted: Bool) -> String {
        if index == 0 {
            return "Pass-through"
        } else if index == 1 {
            return "Incoming Only"
        } else if index == 2 {
            return "Unit"
        } else {
            return "Prefixes"
        }
    }
    
    open override func settingSubtitle(index: Int, highlighted: Bool) -> String? {
        if index == 0 {
            if restartRequired {
                return "Re-open to apply"
            } else {
                if alreadyLaunched {
                    restartRequired = true
                }
                if (highlighted) {
                    return "ON";
                } else {
                    return "OFF";
                }
            }
        } else if index == 1 {
            if (highlighted) {
                return "ON";
            } else {
                return "OFF";
            }
        } else if index == 2 {
            if (highlighted) {
                return "b/s";
            } else {
                return "B/s";
            }
        } else {
            if (highlighted) {
                return "↑↓";
            } else {
                return "▲▼";
            }
        }
    }

    private func settingKey(index: Int) -> String {
        if index == 0 {
            return "passthroughMode"
        } else if index == 1 {
            return "singleLineMode"
        } else if index == 2 {
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
        delegate?.settingDidSelect(key: settingKey(index: index))
        completion()
    }
}