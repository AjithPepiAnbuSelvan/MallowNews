//
//  APIConstants.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//

import Foundation

enum APIConstants {
	static let articlesURL = URL(
		string: "https://api.spaceflightnewsapi.net/v4/articles/"
	)!
	
	static let pageLimit = 20
	static let offsetKey = "offset"
	static let limitKey = "limit"
	static let searchKey = "search"
}
