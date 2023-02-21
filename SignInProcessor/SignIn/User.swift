//
//  User.swift
//
//  Created by Woody Liu on 2023/1/31.
//

import Foundation

public struct User: Hashable {
    /// The user's email address.
    let email: String
    let name: String?
    let providerID: String
    let date: Date
    let someToken: SomeToken
    let firebaseIDToken: String
    let firebaseRefreshToekn: String
}

extension User {
    
    struct UserFactory {
        var someToken: SomeToken?
        var firebaseResponse: FirebaseSignServerResponse
        
        func createUser() -> User? {
            guard let refreshToken = firebaseResponse.refreshToken,
                  let email = firebaseResponse.email,
                  let someToken else { return nil }
            return User(email: email, name: firebaseResponse.name,
                        providerID: firebaseResponse.providerID,
                        date: firebaseResponse.date,
                        someToken: someToken,
                        firebaseIDToken: firebaseResponse.idToken,
                        firebaseRefreshToekn: refreshToken)
        }
    }
    
    
}
