//
//  Combine+Binder.swift
//  SignInProcessor
//
//  Created by Woody Liu on 2023/4/4.
//

import Combine
import Foundation

/**
 [CombineBinder github.gist](https://gist.github.com/woodycatliu/fb5a9fc36f8586271e7ea0dc781f2ac2)
 */
extension Publisher where Failure == Never {
    public func bind(to binder: CombineBinder<Output>) -> AnyCancellable {
        subscribe(binder)
        return AnyCancellable(binder)
    }
}

public struct CombineBinder<Input>: Subscriber, Cancellable {
  
    public typealias Failure = Never
    
   
    public init<Target: AnyObject, Scheduler: Combine.Scheduler>(_ target: Target,
                                                                 scheduler: Scheduler = DispatchQueue.main,
                                                                 binding: @escaping (Target, Input) -> Void) {
        self._bind = { [weak target] input in
            scheduler.schedule { [weak target] in
                if let target = target {
                    binding(target, input)
                }
            }
        }
        
    }
   
    public func receive(_ input: Input) -> Subscribers.Demand {
        self._bind(input)
       return .unlimited
    }
    
    public func receive(subscription: Subscription) {
        self.subscontainter.subscription = subscription
        subscription.request(.unlimited)
    }
    
    public var combineIdentifier: CombineIdentifier {
        return CombineIdentifier()
    }
    
    public func cancel() {
        subscontainter.subscription?.cancel()
    }

    public func receive(completion: Subscribers.Completion<Failure>) {}

    private let _bind: (Input) -> Void
    
    private let subscontainter = SubscriptionContainer()
    
    private class SubscriptionContainer {
        var subscription: Subscription?
    }
}
