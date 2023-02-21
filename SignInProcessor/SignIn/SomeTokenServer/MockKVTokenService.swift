//
//  MockKVTokenService.swift
//
//  Created by Woody Liu on 2023/1/31.
//

import Foundation
import Combine

extension SomeTokenServer.Response {
    fileprivate static var test: Self {
        return .init(someToken: .init(token: "Test KVToken",
                                    refreshToken: "Test KV RefreshToken")
        )
    }
}


struct MockSomeTokenService: SomeTokenServer {
    
    func fetchSomeToken(email: String, idToken: String) -> AnyPublisher<Response, Error> {
        return Just<Response>(Response.test)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchSomeToken(email: String, idToken: String) async throws -> Response {
            try await Task.sleep(for: .seconds(1))
            return Response.test
    }
    
}
