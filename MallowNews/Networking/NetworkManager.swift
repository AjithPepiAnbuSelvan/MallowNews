//
//  NetworkManager.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import Foundation

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

protocol NewsService {
	func fetchArticles(
		query: String?,
		offset: Int,
		limit: Int
	) async throws -> ArticlesResponse
}

final class NetworkManager: NewsService {
	static let shared = NetworkManager()
	
	private let decoder: JSONDecoder
	
	private init() {
		decoder = JSONDecoder()
		
		let dateFormatterWithMilliseconds = ISO8601DateFormatter()
		dateFormatterWithMilliseconds.formatOptions = [
			.withInternetDateTime,
			.withFractionalSeconds
		]
		
		let normalDateFormatter = ISO8601DateFormatter()
		
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
	
	func fetchArticles(
		query: String? = nil,
		offset: Int = 0,
		limit: Int = APIConstants.pageLimit
	) async throws -> ArticlesResponse {
		var components = URLComponents(
			url: APIConstants.articlesURL,
			resolvingAgainstBaseURL: false
		)
		
		var queryItems = [
			URLQueryItem(
				name: APIConstants.limitKey,
				value: String(limit)
			),
			URLQueryItem(
				name: APIConstants.offsetKey,
				value: String(offset)
			)
		]

		let trimmedQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
		if let trimmedQuery, !trimmedQuery.isEmpty {
			queryItems.append(
				URLQueryItem(name: APIConstants.searchKey, value: trimmedQuery)
			)
		}

		components?.queryItems = queryItems
		
		guard let url = components?.url else {
			throw NetworkError.invalidURL
		}
		
		let (data, response) = try await URLSession.shared.data(from: url)
		
		guard let httpResponse = response as? HTTPURLResponse,
			 200...299 ~= httpResponse.statusCode else {
			throw NetworkError.invalidResponse
		}
		
		return try decoder.decode(ArticlesResponse.self, from: data)
	}
}
