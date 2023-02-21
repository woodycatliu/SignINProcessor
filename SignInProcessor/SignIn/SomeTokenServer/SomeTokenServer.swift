//
//  SomeToken.swift
//
//  Created by Woody Liu on 2023/1/31.
//

import Combine

struct SomeToken: Hashable {
    var token: String
    var refreshToken: String
}

struct KVTokenServerResponse {
    let someToken: SomeToken
}

protocol SomeTokenServer {
    
    typealias Response = KVTokenServerResponse
    
    func fetchSomeToken(email: String, idToken: String) -> AnyPublisher<Response, Error>
    
    func fetchSomeToken(email: String, idToken: String) async throws -> Response
}
