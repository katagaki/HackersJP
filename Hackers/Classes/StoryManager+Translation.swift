//
//  StoryManager+Translation.swift
//  Hackers
//
//  Created by シンジャスティン on 2023/08/28.
//

import Foundation
import MLKitTranslate
#if canImport(Translation)
import Translation
#endif

extension StoryManager {

    // MARK: - Translation

    func translateText(_ text: String, translator: Translator, translationService: Int) async throws -> String {
        #if canImport(Translation)
        if translationService == 1 {
            if #available(iOS 26.0, *) {
                if let result = try await translateWithApple(text) {
                    return result
                }
            }
        }
        #endif
        return try await translator.translate(text)
    }

    #if canImport(Translation)
    @available(iOS 26.0, *)
    private func translateWithApple(_ text: String) async throws -> String? {
        let source = Locale.Language(identifier: "en")
        let target = Locale.Language(identifier: "ja")
        let session = TranslationSession(installedSource: source, target: target)
        let response = try await session.translate(text)
        return response.targetText
    }
    #endif
}
