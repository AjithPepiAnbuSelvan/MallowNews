//
//  NetworkManager.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import Foundation

// MARK: - Network Errors

enum NetworkError: LocalizedError {
	case invalidURL
	case invalidResponse

	var errorDescription: String? {
		switch self {
		case .invalidURL: return "The request URL is invalid."
		case .invalidResponse: return "The server returned an invalid response."
		}
	}
}

// MARK: - NewsService Protocol

protocol NewsService {
	func fetchArticles( query: String?, offset: Int, limit: Int ) async throws -> ArticlesResponse
	func clearArticleCache()
	func fetchArticle(id: Int) async throws -> Article
}

extension NewsService {
	func clearArticleCache() { }
	func fetchArticle(id: Int) async throws -> Article { throw NetworkError.invalidURL }
}

// MARK: - NetworkManager Implementation

final class NetworkManager: NewsService {
	// MARK: - Singleton

	static let shared = NetworkManager()

	// MARK: - Properties

	private let pageCache = NSCache<NSURL, CachedPage>()
	private let cacheLifetime: TimeInterval = 300
	
	private let decoder: JSONDecoder
	
	// MARK: - Initialization

	private init() {
		decoder = JSONDecoder()
		
		let dateFormatterWithMilliseconds = ISO8601DateFormatter()
		dateFormatterWithMilliseconds.formatOptions = [
			.withInternetDateTime,
			.withFractionalSeconds
		]
		
		let normalDateFormatter = ISO8601DateFormatter()
		
		// Spaceflight News API timestamps vary between standard ISO8601 and variants with fractional seconds.
		decoder.dateDecodingStrategy = .custom { decoder in
			let container = try decoder.singleValueContainer()
			let dateString = try container.decode(String.self)
			
			if let date = dateFormatterWithMilliseconds.date(from: dateString) {
				return date
			}
			
			if let date = normalDateFormatter.date(from: dateString) {
				return date
			}
			
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Invalid date format: \(dateString)"
			)
		}
	}

	// MARK: - Cache Management

	func clearArticleCache() {
		pageCache.removeAllObjects()
	}
	
	// MARK: - NewsService

	func fetchArticles( query: String? = nil, offset: Int = 0, limit: Int ) async throws -> ArticlesResponse {
		var components = URLComponents( url: APIConstants.articlesURL, resolvingAgainstBaseURL: false )
		
		var queryItems = [
			URLQueryItem( name: APIConstants.limitKey, value: String(limit)),
			URLQueryItem( name: APIConstants.offsetKey, value: String(offset))
		]

		let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
		if let trimmedQuery, !trimmedQuery.isEmpty {
			queryItems.append( URLQueryItem(name: APIConstants.titleContainsKey, value: trimmedQuery))
		}

		components?.queryItems = queryItems
		
		guard let url = components?.url else {
			throw NetworkError.invalidURL
		}

		// Return unexpired cached responses to prevent redundant requests during rapid tab switches.
		if let cached = pageCache.object(forKey: url as NSURL),
		   Date().timeIntervalSince(cached.createdAt) < cacheLifetime {
			return cached.page
		}
		
		let page: ArticlesResponse
		if let trimmedQuery, !trimmedQuery.isEmpty {
            var summaryComponents = components
            summaryComponents?.queryItems = queryItems.map {
                $0.name == APIConstants.titleContainsKey
                    ? URLQueryItem(name: APIConstants.summaryContainsKey, value: trimmedQuery)
                    : $0
            }
            guard let summaryURL = summaryComponents?.url else { throw NetworkError.invalidURL }
            // The v4 API lacks unified full-text search; concurrently query title and summary fields and merge results.
            async let titlePage = fetchPage(from: url)
            async let summaryPage = fetchPage(from: summaryURL)
            page = merge(title: try await titlePage, summary: try await summaryPage, offset: offset, limit: limit)
        } else {
            page = try await fetchPage(from: url)
        }
		pageCache.setObject(CachedPage(page), forKey: url as NSURL)
		return page
	}

	func fetchArticle(id: Int) async throws -> Article {
		guard let url = APIConstants.articleURL(id: id) else { throw NetworkError.invalidURL }
		let (data, response) = try await URLSession.shared.data(from: url)
		guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
			throw NetworkError.invalidResponse
		}
		return try decoder.decode(Article.self, from: data)
	}

	// MARK: - Private Helpers

    private func fetchPage(from url: URL) async throws -> ArticlesResponse {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.invalidResponse
        }
        return try decoder.decode(ArticlesResponse.self, from: data)
    }

    private func merge(title: ArticlesResponse, summary: ArticlesResponse, offset: Int, limit: Int) -> ArticlesResponse {
        var seen = Set<Int>()
        let results = (title.results + summary.results)
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.publishedAt > $1.publishedAt }
        let hasNext = title.next != nil || summary.next != nil
        let next = hasNext ? URL(string: "https://api.spaceflightnewsapi.net/v4/articles/?offset=\(offset + limit)&limit=\(limit)") : nil
        return ArticlesResponse(count: title.count + summary.count, next: next, previous: nil, results: results)
    }
}

// MARK: - Cache Container

private final class CachedPage: NSObject {
	let page: ArticlesResponse
	let createdAt = Date()
	init(_ page: ArticlesResponse) { self.page = page }
}
