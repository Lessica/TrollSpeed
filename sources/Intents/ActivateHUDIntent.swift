//
//  ActivateHUDIntent.swift
//  TrollSpeed
//
//  Created by Lessica on 2024/1/27.
//

#if canImport(AppIntents)
import AppIntents

@available(iOS 16, *)
struct ActivateHUDIntent: AppIntent {
    static let title: LocalizedStringResource = "Open HUD"

    static let description = IntentDescription(
        "Activate the network speed HUD.",
        categoryName: "Utility",
        searchKeywords: [
            "activate",
            "open",
            "hud",
        ]
    )

    func perform() async throws -> some IntentResult {
        if !IsHUDEnabled() {
            SetHUDEnabled(true)
            return .result(value: true)
        }
        return .result(value: false)
    }
}
#endif
