// AppContainer+Stub.swift

#if DEBUG
    import APIClient
    import Foundation
    import Persistence

    extension AppContainer {
        /// The launch argument that starts the app on `stubbed()`. UI tests cannot
        /// import App, so they spell it out.
        static let stubNetworkArgument = "-UITestStubNetwork"

        /// A container over `StubURLProtocol` and an in-memory store, so no UI
        /// test run inherits another's cache.
        static func stubbed() -> AppContainer {
            // Never resolved: `.invalid` cannot reach a real host even if a
            // request escaped the stub.
            guard let baseURL = URL(string: "https://stub.invalid") else {
                fatalError("Malformed stub base URL")
            }

            do {
                return AppContainer(
                    storageProvider: try .inMemory(modelName: "ios_template"),
                    apiClient: APIClient(baseURL: baseURL, session: StubURLProtocol.session())
                )
            } catch {
                fatalError("Could not open the in-memory Core Data store: \(error)")
            }
        }
    }
#endif
