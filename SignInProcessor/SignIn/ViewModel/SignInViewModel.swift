//
//  SignInViewModel.swift
//
//  Created by Woody Liu on 2023/2/2.
//

import Combine

class SignInViewModel {
    
    typealias Action = SignInProcessor.Action
    
    typealias States = SignInProcessor.States
    
    struct Input {
        let viewWillAppear: AnyPublisher<Void, Never>
        let send: AnyPublisher<Action, Never>
    }
    
    struct Output {
        let states: AnyPublisher<States, Never>
    }
    
    func transform(input: Input) -> Output {
        bind(input)
        return Output(states: publisher)
    }
  
    init(processor: ProcessorType = SignInProcessor.testProcessor) {
        self.processor = processor
    }
    
    private var publisher: AnyPublisher<SignInProcessor.States, Never> {
        return processor.publisher
    }
    
    private func send(_ action: SignInProcessor.Action) {
        processor.send(action)
    }
    
    private let processor: ProcessorType

    typealias ProcessorType = SignInProcessor.ProcessorType
    
    private var bag = Set<AnyCancellable>()
    
}

// MARK: Helper
extension SignInViewModel {
    
    fileprivate func bind(_ input: Input) {
        
        bag = Set<AnyCancellable>()
        
        input.viewWillAppear
            .bind(to: viewWillAppearBinder)
            .store(in: &bag)
        
        input.send
            .bind(to: sendAction)
            .store(in: &bag)
    }
    
    fileprivate var viewWillAppearBinder: CombineBinder<Void> {
        return CombineBinder(self) { vm, _ in
            vm.send(.logout)
        }
    }
    
    fileprivate var sendAction: CombineBinder<Action> {
        return CombineBinder(self) { vm, action in
            vm.send(action)
        }
    }
    
}
