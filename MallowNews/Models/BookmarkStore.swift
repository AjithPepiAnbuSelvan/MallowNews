//
//  BookmarkStore.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 20/09/26.
//

import Foundation

@MainActor
final class BookmarkStore {
    // MARK: - Singleton

    static let shared = BookmarkStore()

    // MARK: - Properties

    private let storageKey = "saved-articles"
    private(set) var articles: [Article] = []
    private var observers: [UUID: () -> Void] = [:]

    // MARK: - Initialization

    private init() { load() }

    // MARK: - Bookmark Management

    func contains(_ article: Article) -> Bool {
        articles.contains { $0.id == article.id }
    }

    func toggle(_ article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles.remove(at: index)
        } else {
            articles.insert(article, at: 0)
        }
        save()
        observers.values.forEach { $0() }
    }

    // MARK: - Observers

    @discardableResult
    func addObserver(_ observer: @escaping () -> Void) -> UUID {
        let token = UUID()
        observers[token] = observer
        return token
    }

    func removeObserver(_ token: UUID) {
        observers[token] = nil
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        articles = (try? JSONDecoder.bookmarks.decode([Article].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder.bookmarks.encode(articles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - Codable Helpers

private extension JSONEncoder {
    static let bookmarks: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension JSONDecoder {
    static let bookmarks: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
