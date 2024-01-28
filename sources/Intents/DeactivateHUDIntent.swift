//
//  DeactivateHUDIntent.swift
//  TrollSpeed
//
//  Created by Lessica on 2024/1/27.
//

#if canImport(AppIntents)
import AppIntents

@available(iOS 16, *)
struct DeactivateHUDIntent: AppIntent {
    static let title: LocalizedStringResource = "Exit HUD"

    static let description = IntentDescription(
        "Deactivate the network speed HUD.",
        categoryName: "Utility",
        searchKeywords: [
            "deactivate",
            "exit",
            "hud",
        ]
    )

    func perform() async throws -> some IntentResult {
        if IsHUDEnabled() {
            SetHUDEnabled(false)
            return .result(value: true)
        }
        return .result(value: false)
    }
}
#endif
