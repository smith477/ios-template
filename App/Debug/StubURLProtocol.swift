// StubURLProtocol.swift

#if DEBUG
    import Foundation

    /// Answers the app's requests from `StubFixtures` instead of the network, so the
    /// UI tests do not go red when dummyjson.com is slow or down.
    ///
    /// Routes on the path alone, because the app sends no query items. A request it
    /// does not know answers 404: a new endpoint then fails visibly in a stubbed run
    /// rather than quietly reaching for the network.
    ///
    /// The file is DEBUG-only, fixtures included, so none of it reaches a Release
    /// build. `nonisolated` because `URLSession` calls a protocol off the main
    /// actor, which the App target otherwise defaults to.
    nonisolated class StubURLProtocol: URLProtocol {
        /// A session answered entirely by this protocol. Ephemeral, so no response
        /// is cached to disk between runs.
        static func session() -> URLSession {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [StubURLProtocol.self]
            return URLSession(configuration: configuration)
        }

        /// The fixture body for a request, or `nil` for one the stub does not serve.
        static func fixture(method: String, path: String) -> String? {
            guard method == "GET" else { return nil }

            switch path {
            case "/products": return StubFixtures.products
            case "/users": return StubFixtures.users
            default: return nil
            }
        }

        override static func canInit(with _: URLRequest) -> Bool {
            true
        }

        override static func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            guard let url = request.url else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }

            let body = Self.fixture(method: request.httpMethod ?? "GET", path: url.path)
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: body == nil ? 404 : 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            ) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data((body ?? "{}").utf8))
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
#endif
