//
//  SignInProcessorTests.swift
//  SignInProcessorTests
//
//  Created by Woody Liu on 2023/2/18.
//

import XCTest
@testable import SignInProcessor

final class SignInProcessorTests: XCTestCase {
    
    let user = User(email: "Default@example.com", name: "Default", providerID: "Test Firebase provideID", date: Date(timeIntervalSince1970: 12345), someToken: .init(token: "Test KVToken", refreshToken: "Test KV RefreshToken"), firebaseIDToken: "Test Firebase idToken", firebaseRefreshToekn: "Test Firebase refreshToken")
    
    var processor: SignInProcessor.ProcessorType!
    
    override func setUpWithError() throws {
        processor = SignInProcessor.testProcessor
        processor.enableLog = false
    }
    
    override func tearDownWithError() throws {
        processor = nil
    }
    
    func testPrivationAction() async throws {
        
        await processor.test.privateAction(sendAction: .appleSignIn, where: {
            action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.appleSignIn = action {
                return true
            }
            return false
        }).privateAction(send: .appleSignIn, message: "123", where: { action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.storeAppleUser = action {
                return true
            }
            return false
        }).privateAction(send: .fetchSomeToken(userFactory: .init(someToken: .init(token: "test", refreshToken: "test"),
                                                                  firebaseResponse: .test),
                                               email: "Test",
                                               idToken: "Test"), message: "456", where: {
            action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.storeUser = action {
                return true
            }
            return false
        }).privateAction(send: .updateStauts(.didSignIn(user: user)), where: {
            $0 == nil
        })
        
        await processor.test.output
            .privateAction(sendAction: .appleSignIn, where: { action in
                guard let action else { return false }
                if case SignInProcessor.PrivateAction.appleSignIn = action {
                    return true
                }
                return false
            })
        
        await processor.test.output
            .privateAction(send: .appleSignIn, message: "789", where: { action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.storeAppleUser = action {
                return true
            }
            return false
        })
        
    }
    
    func testState() async throws {
        
        await processor.test
            .state(send: .updateStauts(.isSignIning), equal: .init(stauts: .isSignIning))
            .state(send: .updateStauts(.error(err: NSError(domain: "", code: 0))), equal: .init(stauts: .error(err: NSError(domain: "", code: 0))))
            .state(send: .updateStauts(.ready), keyPath: \.stauts, equal: .init(stauts: .ready))
        
        await processor.test.output.state(send: .updateStauts(.isSignIning), equal: .init(stauts: .isSignIning))
        await processor.test.output.state(send: .updateStauts(.error(err: NSError(domain: "", code: 0))), equal: .init(stauts: .error(err: NSError(domain: "", code: 0))))
        await processor.test.output.state(send: .updateStauts(.ready), keyPath: \.stauts, equal: .init(stauts: .ready))
    }
    
    func testComposable() async throws {
        await processor.test.composable.privateAction(sendAction: .appleSignIn, where: { action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.appleSignIn = action {
                return true
            }
            return false
        })
        .nextPrivateAction(where: { action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.storeAppleUser = action {
                return true
            }
            return false
        }).nextPrivateAction(where: {action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.signInProviderID = action {
                return true
            }
            return false
        })
        .nextPrivateAction(where: {action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.updateFirebaseInfoIfNeed = action {
                return true
            }
            return false
        }).nextPrivateAction(where: {action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.update = action {
                return true
            }
            return false
        })
        .nextPrivateAction(where: {action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.fetchSomeToken = action {
                return true
            }
            return false
        })
        .nextPrivateAction(where: {action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.storeUser = action {
                return true
            }
            return false
        })
        .nextPrivateAction(where: {action in
            guard let action else { return false }
            if case SignInProcessor.PrivateAction.updateStauts = action {
                return true
            }
            return false
        })
        .final(equal: .init(stauts: .didSignIn(user: user)))
        
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
