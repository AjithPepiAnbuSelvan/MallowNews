//
//  ArticleFormatting.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 20/09/26.
//

import Foundation

// MARK: - Relative Date Formatting

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
