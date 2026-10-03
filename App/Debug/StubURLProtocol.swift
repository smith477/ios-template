// StubURLProtocol.swift

#if DEBUG
    import Foundation

    /// A URL protocol that answers the app's requests from `StubFixtures`.
    ///
    /// Routes on the path alone, and answers 404 for a path it does not know, so a
    /// new endpoint fails visibly rather than reaching the network. `nonisolated`
    /// because `URLSession` calls it off the main actor.
    nonisolated class StubURLProtocol: URLProtocol {
        /// An ephemeral session answered entirely by this protocol.
        static func session() -> URLSession {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [StubURLProtocol.self]
            return URLSession(configuration: configuration)
        }

        /// Returns the fixture body for a request, or `nil` for one the stub does
        /// not serve.
        static func fixture(method: String, path: String) -> String? {
            guard method == "GET" else { return nil }

            switch path {
            case "/products": return StubFixtures.products
            case "/users": return StubFixtures.users
            default: return productFixture(path: path)
            }
        }

        /// Returns the body for `/products/{id}`, or `nil` for an id without a
        /// fixture.
        private static func productFixture(path: String) -> String? {
            let components = path.split(separator: "/")
            guard components.count == 2, components[0] == "products",
                  let id = Int(components[1]) else { return nil }
            return StubFixtures.product[id]
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
