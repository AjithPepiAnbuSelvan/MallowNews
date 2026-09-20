//
//  ImageLoader.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import UIKit

final class ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {}

    func image(from url: URL) async throws -> UIImage {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        if components.scheme?.lowercased() == "http" {
            components.scheme = "https"
        }
        guard components.scheme?.lowercased() == "https", let url = components.url else {
            throw NetworkError.invalidURL
        }
        if let cachedImage = cache.object(forKey: url as NSURL) {
            return cachedImage
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode,
              let image = UIImage(data: data) else {
            throw NetworkError.invalidResponse
        }

        cache.setObject(image, forKey: url as NSURL)

        return image
    }
}
