//
//  Topic.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 20/09/26.
//

import Foundation

enum Topic: String, CaseIterable {
    // MARK: - Cases

    case all = "All"
    case space = "Space"
    case launches = "Launches"
    case moon = "Moon"
    case mars = "Mars"
    case nasa = "NASA"
    case esa = "ESA"

    // MARK: - Query Mapping

    var query: String? { self == .all ? nil : rawValue }
}
