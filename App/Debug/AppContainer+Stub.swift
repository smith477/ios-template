// AppContainer+Stub.swift

#if DEBUG
    import APIClient
    import Foundation
    import Persistence

    extension AppContainer {
        /// The launch argument that starts the app on `stubbed()`. UI tests pass
        /// it in `launchArguments`; they cannot import App, so they spell it out.
        static let stubNetworkArgument = "-UITestStubNetwork"

        /// A container that never touches the network or the on-disk store:
        /// requests are answered by `StubURLProtocol`, and the store is in
        /// memory, so one UI test run cannot inherit another's cached products.
        static func stubbed() -> AppContainer {
            // Never resolved: every request on the stub session is answered
            // before it leaves the process. `.invalid` guarantees that even a
            // request that escaped could not reach a real host.
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
