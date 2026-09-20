//
//  FeedViewModel.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import Foundation

@MainActor
final class FeedViewModel {

    enum State {
        case idle
        case loading
        case loaded
        case empty
        case failed(String)
    }

    private(set) var articles: [Article] = []
    private(set) var featuredArticle: Article?
    private(set) var latestArticles: [Article] = []
    private(set) var nextPageURL: URL?
    private(set) var isRefreshing = false
    private(set) var isLoadingNextPage = false {
        didSet { onPaginationChange?(isLoadingNextPage) }
    }
    private(set) var state: State = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((State) -> Void)?
    var onPaginationChange: ((Bool) -> Void)?

    private let service: NewsService
    private var activeQuery: String?
    private var searchTask: Task<Void, Never>?
    // Every replacement invalidates older initial and pagination responses.
    private var generation = UUID()

    init(service: NewsService = NetworkManager.shared) {
        self.service = service
    }

    func loadArticles() async {
        await loadInitial()
    }

    func loadInitial(query: String? = nil) async {
        searchTask?.cancel()
        activeQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = beginReplacement()
        await fetchInitial(token: token)
    }

    private func beginReplacement() -> UUID {
        generation = UUID()
        nextPageURL = nil
        isLoadingNextPage = false
        isRefreshing = false
        state = .loading
        return generation
    }

    private func fetchInitial(token: UUID) async {
        let query = activeQuery
        do {
            let response = try await service.fetchArticles(
                query: query,
                offset: 0,
                limit: APIConstants.pageLimit
            )
            guard token == generation, !Task.isCancelled else { return }
            applyInitial(response)
            state = articles.isEmpty ? .empty : .loaded
        } catch {
            guard token == generation, !Task.isCancelled else { return }
            state = .failed(error.localizedDescription)
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        searchTask?.cancel()
        let token = beginReplacement()
        isRefreshing = true
        await fetchInitial(token: token)
        if token == generation { isRefreshing = false }
    }

    func retry() async {
        await loadInitial(query: activeQuery)
    }

    func search(for query: String) {
        searchTask?.cancel()
        activeQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        articles = []
        featuredArticle = nil
        latestArticles = []
        let token = beginReplacement()
        searchTask = Task { [weak self] in
			try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.fetchInitial(token: token)
        }
    }

    func loadNextPage() async {
        guard case .loaded = state, !isRefreshing, !isLoadingNextPage,
			  let nextURL = nextPageURL,
			  let offset = nextOffset(from: nextURL) else { return }

        isLoadingNextPage = true
        let token = generation
        defer { if token == generation { isLoadingNextPage = false } }

        do {
            let response = try await service.fetchArticles(
                query: activeQuery,
                offset: offset,
                limit: APIConstants.pageLimit
            )
            guard token == generation, !Task.isCancelled else { return }
            var existingIDs = Set(articles.map(\.id))
            articles.append(contentsOf: response.results.filter { existingIDs.insert($0.id).inserted })
            nextPageURL = response.next
            splitArticles()
            state = .loaded
        } catch {
            // Preserve loaded content when a later page fails.
        }
    }

    func article(withID id: Int) -> Article? {
        articles.first { $0.id == id }
    }

    private func applyInitial(_ response: ArticlesResponse) {
        var ids = Set<Int>()
        articles = response.results.filter { ids.insert($0.id).inserted }
        nextPageURL = response.next
        splitArticles()
    }

    private func splitArticles() {
        featuredArticle = articles.first(where: \.featured) ?? articles.first
        latestArticles = articles.filter { $0.id != featuredArticle?.id }
    }

    private func nextOffset(from url: URL) -> Int? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == APIConstants.offsetKey })?
            .value
            .flatMap(Int.init)
    }
}
