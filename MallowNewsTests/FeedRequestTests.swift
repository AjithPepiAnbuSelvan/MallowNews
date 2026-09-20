import XCTest
@testable import MallowNews

@MainActor
final class FeedRequestTests: XCTestCase {
    private final class Service: NewsService {
        struct Request {
            let query: String?
            let offset: Int
            let continuation: CheckedContinuation<ArticlesResponse, Error>
        }
        var requests: [Request] = []
        func fetchArticles(query: String?, offset: Int, limit: Int) async throws -> ArticlesResponse {
            try await withCheckedThrowingContinuation { continuation in
                requests.append(Request(query: query, offset: offset, continuation: continuation))
            }
        }
    }

    private func page(_ id: Int, next: Bool = false) -> ArticlesResponse {
        ArticlesResponse(count: 2,
            next: next ? URL(string: "https://api.spaceflightnewsapi.net/v4/articles/?offset=20") : nil,
            previous: nil,
            results: [Article(id: id, title: "Story \(id)", authors: [],
                url: URL(string: "https://example.com")!, imageURL: nil,
                newsSite: "Source", summary: "Summary", publishedAt: Date(),
                updatedAt: Date(), featured: false)])
    }

    private func waitForRequests(_ count: Int, service: Service) async {
        for _ in 0..<1000 {
            if service.requests.count >= count { return }
            await Task.yield()
        }
        XCTFail("Request did not start")
    }

    func testOlderInitialResponseCannotOverwriteNewSearch() async {
        let service = Service()
        let model = FeedViewModel(service: service)
        let old = Task { await model.loadInitial(query: "old") }
        await waitForRequests(1, service: service)
        let new = Task { await model.loadInitial(query: "new") }
        await waitForRequests(2, service: service)
        service.requests[1].continuation.resume(returning: page(2))
        await new.value
        service.requests[0].continuation.resume(returning: page(1))
        await old.value
        XCTAssertEqual(model.articles.map(\.id), [2])
    }

    func testOldPaginationCannotAppendAfterRefresh() async {
        let service = Service()
        let model = FeedViewModel(service: service)
        let initial = Task { await model.loadInitial(query: "moon") }
        await waitForRequests(1, service: service)
        service.requests[0].continuation.resume(returning: page(1, next: true))
        await initial.value
        let pagination = Task { await model.loadNextPage() }
        await waitForRequests(2, service: service)
        await model.loadNextPage()
        XCTAssertEqual(service.requests.count, 2)
        let refresh = Task { await model.refresh() }
        await waitForRequests(3, service: service)
        XCTAssertEqual(service.requests[2].query, "moon")
        service.requests[2].continuation.resume(returning: page(3))
        await refresh.value
        service.requests[1].continuation.resume(returning: page(2))
        await pagination.value
        XCTAssertEqual(model.articles.map(\.id), [3])
    }

    func testRetryPreservesFailedQuery() async {
        let service = Service()
        let model = FeedViewModel(service: service)
        let initial = Task { await model.loadInitial(query: "mars") }
        await waitForRequests(1, service: service)
        service.requests[0].continuation.resume(throwing: URLError(.notConnectedToInternet))
        await initial.value
        let retry = Task { await model.retry() }
        await waitForRequests(2, service: service)
        XCTAssertEqual(service.requests[1].query, "mars")
        XCTAssertEqual(service.requests[1].offset, 0)
        service.requests[1].continuation.resume(returning: page(4))
        await retry.value
        XCTAssertEqual(model.featuredArticle?.id, 4)
        XCTAssertTrue(model.latestArticles.isEmpty)
    }
}
