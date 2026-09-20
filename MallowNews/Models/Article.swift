//
//  Article.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 20/09/26.
//

import Foundation

struct ArticlesResponse: Codable {
	let count: Int
	let next: URL?
	let previous: URL?
	let results: [Article]
}

struct Article: Codable {
	let id: Int
	let title: String
	let authors: [Author]
	let url: URL
	let imageURL: URL?
	let newsSite: String
	let summary: String
	let publishedAt: Date
	let updatedAt: Date
	let featured: Bool
	
	enum CodingKeys: String, CodingKey {
		case id
		case title
		case authors
		case url
		case imageURL = "image_url"
		case newsSite = "news_site"
		case summary
		case publishedAt = "published_at"
		case updatedAt = "updated_at"
		case featured
	}
}

struct Author: Codable {
	let name: String
}
