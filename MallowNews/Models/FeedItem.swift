//
//  FeedItem.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 20/09/26.
//

import Foundation

/// Differentiates collection view items by section so diffable data source snapshots maintain unique item identifiers.
nonisolated enum FeedItem: Hashable, Sendable {
    case hero(Int)
    case latest(Int)

    // MARK: - Properties

    var articleID: Int {
        switch self {
        case let .hero(id), let .latest(id):
            return id
        }
    }
}
