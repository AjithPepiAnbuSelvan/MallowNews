//
//  APIConstants.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import Foundation

enum APIConstants {
	// MARK: - Endpoints

	static let articlesURL = URL(
		string: "https://api.spaceflightnewsapi.net/v4/articles/"
	)!
	
	// MARK: - Parameters & Pagination

	static let pageLimit = 20
	static let offsetKey = "offset"
	static let limitKey = "limit"
	static let titleContainsKey = "title_contains"
	static let summaryContainsKey = "summary_contains"

	// MARK: - URL Builders

	static func articleURL(id: Int) -> URL? {
		articlesURL.appendingPathComponent(String(id))
	}
}
