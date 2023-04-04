//
//  SignInAction.swift
//
//  Created by Woody Liu on 2023/1/31.
//

import Combine
import CombineProcessor

struct SignInProcessor {
    
    typealias ProcessorType = Processor<States, Action, PrivateAction>
    
    static var testProcessor: ProcessorType {
        Processor(initialState: States(stauts: .ready),
                  reducer: Self.reducer,
                  environment: Environment.test)
    }
    
    static var reducer: AnyProcessorReducer<States, Action, PrivateAction, Environment> {
        return AnyProcessorReducer(mutated: { action in
            return action.privateAction
        }, reduce: { states, privateAction, environment -> ProcessorPublisher<PrivateAction, Never>? in
            
            switch privateAction {
                
            case .appleSignIn:
                states.stauts = .isSignIning
                return environment
                    .appleService.tryStart()
                    .catchToDeresultProcessor(onSuccess: PrivateAction.storeAppleUser,
                                              onError: PrivateAction.receiveError)
                
            case .signInEmail(with: let email, password: let password):
                states.stauts = .isSignIning
                return environment
                    .firebaseService
                    .signIn(with: email, password: password)
                    .catchToDeresultProcessor(onSuccess: { response in
                        return .fetchSomeToken(userFactory:
                                .init(firebaseResponse: response),
                                               email: response.email ?? "Null",
                                               idToken: response.idToken)
                    }, onError: PrivateAction.receiveError)
                
            case .signInProviderID(appleUser: let appleUser):
                return environment.signInAppleUser(appleUser)
                    .catchToDeresultProcessor(onSuccess: { response in
                        return .updateFirebaseInfoIfNeed(response: response.response,
                                                         appleUser: response.appleUser)
                    }, onError: PrivateAction.receiveError)
                
            case .update(response: let response, name: let name, email: let email):
                return environment
                    .firebaseService
                    .update(response, name: name, email: email)
                    .catchToDeresultProcessor(onSuccess: { response in
                        return .fetchSomeToken(userFactory:
                                .init(firebaseResponse: response),
                                               email: response.email ?? "Null",
                                               idToken: response.idToken)
                    }, onError: PrivateAction.receiveError)
                
            case .fetchSomeToken(userFactory: let userFactory, email: let email, idToken: let idToken):
                return environment.fetchSomeToken(userFactory: userFactory,
                                                  email: email,
                                                  idToken: idToken)
                .catchToDeresultProcessor(onSuccess: { response in
                    if let user = response.createUser() {
                        return .storeUser(user)
                    }
                    return .updateStauts(.error(err: SignInError.unknown))
                }, onError: PrivateAction.receiveError)
                
            case .storeAppleUser(let appleUser):
                return .send(PrivateAction.signInProviderID(appleUser: appleUser))
                
            case .updateFirebaseInfoIfNeed(response: let response, appleUser: let appleUser):
                guard response.email == nil || response.name == nil else {
                    return .send(.fetchSomeToken(userFactory: .init(firebaseResponse: response),
                                                 email: response.email!,
                                                 idToken: response.idToken))
                }
                
                let (email, name) = environment.readAppleUser(appleUser.user)
                
                return .send(.update(response: response,
                                     name: name,
                                     email: email))
                
            case .receiveError(let error):
                return .send(.updateStauts(.error(err: error)))
                
            case .updateStauts(let status):
                states.stauts = status
                return nil
            case .ready:
                return .send(.updateStauts(.ready))
            case .storeUser(let user):
                return .send(.updateStauts(.didSignIn(user: user)))
            }
        })
    }
}

extension SignInProcessor {
    
    // MARK: Action
    
    enum Action {
        
        case appleSignIn
        
        case emailSignIn(_ email: String, _ password: String)
        
        case logout
        
        var privateAction: PrivateAction {
            switch self {
            case .appleSignIn: return .appleSignIn
            case .emailSignIn(let emil, let password): return .signInEmail(with: emil, password: password)
            case .logout: return .ready
            }
        }
    }
    
    enum PrivateAction {
        
        case appleSignIn
        case signInEmail(with: String,
                         password: String)
        
        case signInProviderID(appleUser: AppleUser)
        case update(response: FirebaseSignInServer.Response,
                    name: String,
                    email: String)
        
        case fetchSomeToken(userFactory: User.UserFactory,
                            email: String,
                            idToken: String)
        case storeUser(_ ueser: User)
        
        case storeAppleUser(_ appleUser: AppleUser)
        case updateFirebaseInfoIfNeed(response: FirebaseSignServerResponse, appleUser: AppleUser)
        
        case receiveError(_ error: Error)
        
        case updateStauts(_ status: SignInStatus)
        case ready
    }
    
    // MARK: States
    
    struct States: Equatable {
        var stauts: SignInStatus
    }
    
    // MARK: Environment
    
    struct Environment {
        
        let appleService: AppleSignInServer
        
        let firebaseService: FirebaseSignInServer
        
        let someTokenService: SomeTokenServer
        
        static let test: Environment = .init(appleService: MockAppleSignInService(),
                                             firebaseService: MockFirebaseSignInService(),
                                             someTokenService: MockSomeTokenService())
        
        func fetchSomeToken(userFactory: User.UserFactory, email: String, idToken: String) -> AnyPublisher<User.UserFactory, Error> {
            print("userFactory:", userFactory)
            return someTokenService.fetchSomeToken(email: email, idToken: idToken)
                .map { response -> User.UserFactory in
                    var userFactory = userFactory
                    userFactory.someToken = response.someToken
                    return userFactory
                }.eraseToAnyPublisher()
        }
        
        func signInAppleUser(_ appleUser: AppleUser) -> AnyPublisher<(appleUser: AppleUser, response: FirebaseSignServerResponse), Error> {
            return firebaseService
                .signIn(withProviderID: "apple.com", idToken: appleUser.identityToken, nonce: appleUser.nonce)
                .map { (appleUser, $0) }
                .eraseToAnyPublisher()
        }
        
        func storeAppleUser(appleUser: AppleUser) -> AnyPublisher<AppleUser, Error> {
            return Deferred {
                Future { promise in
                    if let email = appleUser.email {
                        // dosomething
                        print(email)
                    }
                    promise(.success(appleUser))
                }
            }.eraseToAnyPublisher()
        }
        
        func readAppleUser(_ account: String) -> (email: String, name: String) {
            return ("Default@example.com", "Default")
        }
        
    }
    
}

enum SignInStatus: Equatable {
    
    static func == (lhs: SignInStatus, rhs: SignInStatus) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready) :
            return true
        case (.isSignIning, isSignIning):
            return true
        case (.didSignIn(user: let user1), .didSignIn(user: let user2)):
            return user1 == user2
        case (.error(err: let err1), .error(err: let err2)):
            return err1.localizedDescription == err2.localizedDescription
        default:
            return false
        }
    }
    
    case ready
    case isSignIning
    case didSignIn(user: User)
    case error(err: Error)
    
    var user: User? {
        if case Self.didSignIn(user: let user) = self {
            return user
        }
        return nil
    }
}

enum SignInError: Error {
    case unknown
}

extension SignInProcessor.Action: CustomStringConvertible {
    
    var description: String {
        switch self {
        case .logout: return "logout"
        case .emailSignIn: return "emailSignIn"
        case .appleSignIn: return "appleSignIn"
        }
    }
}

extension SignInProcessor.PrivateAction: CustomStringConvertible {
    var description: String {
        switch self {
            
        case .appleSignIn: return "appleSignIn"
        case .signInEmail(with: let with, password: let password): return "signInEmail: \(with), password: \(password)"
        case .signInProviderID(appleUser: let appleUser): return "signInProviderID: \(appleUser.user)"
        case .update(response: let response, _, _): return "update: \(response.userId)"
        case .fetchSomeToken(_, let email, _): return "fetchSomeToken \(email)"
        case .storeUser: return "storeUser"
        case .storeAppleUser: return "storeAppleUser"
        case .updateFirebaseInfoIfNeed: return "updateFirebaseInfoIfNeed"
        case .updateStauts: return "updateStauts"
        case .ready: return "ready"
        case .receiveError(let error): return "receiveError: \(error)"
        }
    }
}
