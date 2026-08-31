import Foundation

/// Role: Persistence. Typed transport failures. This product has no remote catalog.
enum KilnClientError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Persistence. Sends one HTTP request. Injected so tests never hit the network.
protocol KilnTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Persistence. URLSession transport, 15 s timeout, app User-Agent on every request.
struct KilnSessionTransport: KilnTransport {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": KilnClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Persistence. JSON number or numeric string; missing stays nil.
struct KilnJSONNumber: Sendable, Equatable {
    var value: Double?
}

extension KilnJSONNumber: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Persistence. Owns the session. Offline kiln — transport seam only.
actor KilnClient {
    static let userAgent = "Kilncast/1.0 (iOS; +https://kilncast.pro)"

    private let transport: any KilnTransport

    init(transport: any KilnTransport) {
        self.transport = transport
    }

    init() {
        self.transport = KilnSessionTransport()
    }

    func getJSON<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let data = try await fetch(makeRequest(url: url))
        do {
            return try JSONDecoder().decode(DTO.self, from: data)
        } catch is CancellationError {
            throw KilnClientError.cancelled
        } catch {
            throw KilnClientError.decoding
        }
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as KilnClientError {
            throw error
        } catch is CancellationError {
            throw KilnClientError.cancelled
        } catch {
            if kilnIsCancelled(error) {
                throw KilnClientError.cancelled
            }
            guard kilnIsTransient(error) else { throw KilnClientError.transport }
            do {
                return try await send(request)
            } catch let error as KilnClientError {
                throw error
            } catch is CancellationError {
                throw KilnClientError.cancelled
            } catch {
                if kilnIsCancelled(error) { throw KilnClientError.cancelled }
                throw KilnClientError.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw KilnClientError.invalidResponse
        }
        if http.statusCode == 404 {
            throw KilnClientError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw KilnClientError.transport
        }
        return data
    }
}

func kilnIsTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

func kilnIsCancelled(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
