//
//  ToggleHUDIntent.swift
//  TrollSpeed
//
//  Created by Lessica on 2024/1/27.
//

#if canImport(AppIntents)
import AppIntents

@available(iOS 16, *)
struct ToggleHUDIntent: AppIntent {
    static let title: LocalizedStringResource = "Toggle HUD"

    static let description = IntentDescription(
        "Toggle the network speed HUD.",
        categoryName: "Utility",
        searchKeywords: [
            "toggle",
            "exit",
            "hud",
        ]
    )

    func perform() async throws -> some IntentResult {
        SetHUDEnabled(!IsHUDEnabled())
        return .result(value: true)
    }
}
#endif
