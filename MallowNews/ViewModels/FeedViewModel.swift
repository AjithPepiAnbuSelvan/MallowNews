//
//  FeedViewModel.swift
//  MallowNews
//
//  Created by Ajith Pepi Anbu Selvan on 21/09/26.
//


import Foundation

@MainActor
final class FeedViewModel {
    // MARK: - View State

    enum State {
        case idle
        case loading
        case loaded
        case empty
        case failed(String)
    }

    // MARK: - Properties

    private(set) var articles: [Article] = []
    private(set) var featuredArticle: Article?
    private(set) var latestArticles: [Article] = []
    private(set) var nextPageURL: URL?
    private(set) var isRefreshing = false
    private(set) var isLoadingNextPage = false {
        didSet { onPaginationChange?(isLoadingNextPage) }
    }
    private(set) var paginationError: String? {
        didSet { onPaginationError?(paginationError) }
    }
    private(set) var state: State = .idle {
        didSet {
            onStateChange?(state)
        }
    }

    // MARK: - Callbacks

    var onStateChange: ((State) -> Void)?
    var onPaginationChange: ((Bool) -> Void)?
    var onPaginationError: ((String?) -> Void)?

    // MARK: - Dependencies & Concurrency

    private let service: NewsService
    private var activeQuery: String?
    private var searchTask: Task<Void, Never>?
    // Request-generation tokens prevent stale or out-of-order API responses from overwriting newer search or refresh queries.
    private var generation = UUID()

    // MARK: - Initialization

    init(service: NewsService? = nil) {
        self.service = service ?? NetworkManager.shared
    }

    // MARK: - Feed Loading

    func loadArticles() async {
        await loadInitial()
    }

    func loadInitial(query: String? = nil) async {
        searchTask?.cancel()
        activeQuery = query?.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = beginReplacement()
        await fetchInitial(token: token)
    }

    private func beginReplacement(isRefreshing: Bool = false) -> UUID {
        generation = UUID()
        nextPageURL = nil
        isLoadingNextPage = false
        self.isRefreshing = isRefreshing
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

    // MARK: - Refresh & Retry

    func refresh() async {
        guard !isRefreshing else { return }
        searchTask?.cancel()
        service.clearArticleCache()
        let token = beginReplacement(isRefreshing: true)
        await fetchInitial(token: token)
        if token == generation { isRefreshing = false }
    }

    func retry() async {
        await loadInitial(query: activeQuery)
    }

    // MARK: - Search

    func search(for query: String) {
        searchTask?.cancel()
        activeQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let token = beginReplacement()
        searchTask = Task { [weak self] in
            // Debounce user keystrokes to reduce network thrash while typing.
			try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.fetchInitial(token: token)
        }
    }

    // MARK: - Pagination

    func loadNextPage() async {
        guard case .loaded = state, !isRefreshing, !isLoadingNextPage, let nextURL = nextPageURL, let offset = nextOffset(from: nextURL) else { return }
        isLoadingNextPage = true
        paginationError = nil
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
            guard token == generation, !Task.isCancelled else { return }
            paginationError = error.localizedDescription
        }
    }

    func retryNextPage() async { await loadNextPage() }

    // MARK: - Helpers

    func article(withID id: Int) -> Article? {
        articles.first { $0.id == id }
    }

    private func applyInitial(_ response: ArticlesResponse) {
        var ids = Set<Int>()
        articles = response.results.filter { ids.insert($0.id).inserted }
        nextPageURL = response.next
        featuredArticle = nil
        splitArticles()
    }

    private func splitArticles() {
        // Hero selection must remain stable while paginating; only assign on initial load so later pages don't swap the hero.
        if featuredArticle == nil {
            featuredArticle = articles.first(where: \.featured) ?? articles.first
        }
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
