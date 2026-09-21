//
//  ArticleDetailViewModel.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import Foundation

@MainActor
final class ArticleDetailViewModel {
    // MARK: - Properties

    private let service: NewsService
    private(set) var article: Article

    // MARK: - Initialization

    init(article: Article, service: NewsService? = nil) {
        self.article = article
        self.service = service ?? NetworkManager.shared
    }

    // MARK: - Networking

    /// Loads the latest full article detail from the network if available, falling back to the cached summary.
    func loadDetail() async -> Article {
        guard let detailedArticle = try? await service.fetchArticle(id: article.id) else { return article }
        article = detailedArticle
        return detailedArticle
    }
}
