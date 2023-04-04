//
//  ViewController.swift
//  SignInProcessor
//
//  Created by Woody Liu on 2023/2/18.
//

import UIKit
import Combine
import CombineProcessor

typealias PrivateAction = SignInProcessor.PrivateAction
class ViewController: UIViewController {
    
    let viewModel = SignInViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        bind(viewModel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppear.send(())
    }
    
    private func setUI() {
        let contentView = ContentView()
        view.addSubview(contentView)
        contentView.fillFullInSuperview()
        contentView.emailBtn.addTarget(self, action: #selector(emailAction), for: .touchUpInside)
        contentView.appleBtn.addTarget(self, action: #selector(appleAction), for: .touchUpInside)
        
        view.addSubview(loadingView)
        loadingView.fillFullInSuperview()
    }
    
    @objc private func appleAction() {
        sendAction.send(.appleSignIn)
    }
    
    @objc private func emailAction() {
        emailSigInAlert()
    }
    
    private let sendAction = PassthroughSubject<SignInViewModel.Action, Never>()
    
    private let loadingView = UIActivityIndicatorView(style: .large)
    
    private let viewWillAppear = PassthroughSubject<Void, Never>()
    
    private var bag = Set<AnyCancellable>()
}

// MARK: Bind
fileprivate extension ViewController {
    
    func bind(_ viewModel: SignInViewModel) {
        
       let output = viewModel.transform(input: .init(viewWillAppear: viewWillAppear.eraseToAnyPublisher(),
                                         send: sendAction.eraseToAnyPublisher()))
        output.states
            .map(\.stauts)
            .compactMap(\.user)
            .bind(to: successSingIn)
            .store(in: &bag)
        
        output.states
            .map(\.stauts)
            .bind(to: statusBinder)
            .store(in: &bag)
    }
    
    var statusBinder: CombineBinder<SignInStatus> {
        return CombineBinder(self) { vc, status in
            
            vc.loadingView.stopAnimating()
            switch status {
            case .ready, .didSignIn: break
            case .error(err: let error):
                vc.errorAlert(error)
            case .isSignIning:
                vc.loadingView.startAnimating()
            }
        }
    }
    
    var successSingIn: CombineBinder<User> {
        return CombineBinder(self) { vc, user in
            vc.present(UserViewController(user: user), animated: true)
        }
    }
}

// MARK: Alert
fileprivate extension ViewController {
    
    func errorAlert(_ error: Error) {
        let alertController = UIAlertController(title: "Sign In Error", message: error.localizedDescription, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    
    func emptyAlert() {
        let alertController = UIAlertController(title: "Email Error", message: "Email or Password is Empty.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    func emailSigInAlert() {
        let controller = UIAlertController(title: nil, message: "Enter Email & Password", preferredStyle: .alert)
        
        
        controller.addTextField { (textField) in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        
        controller.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.keyboardType = .default
        }
        
        controller.addAction(UIAlertAction(title: "確定", style: .default, handler: { (_) in
            
            guard let textFields = controller.textFields else {return}
            
            guard let email = textFields[0].text,
                  let password = textFields[0].text,
                  !email.isEmpty && !password.isEmpty else {
                self.emptyAlert()
                return
            }
            
            self.sendAction.send(.emailSignIn(email, password))
            
        }))
        
        controller.addAction(UIAlertAction(title: "取消", style: .default, handler: { (_) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(controller, animated: true, completion: nil)
    }
}

fileprivate extension ViewController {
    
    class ContentView: UIView {
        
        let appleBtn: UIButton = {
            let btn = UIButton(type: .system)
            btn.titleLabel?.font = .systemFont(ofSize: 30, weight: .heavy)
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.titleLabel?.layer.borderColor = UIColor.separator.cgColor
            btn.titleLabel?.layer.borderWidth = 0.5
            btn.titleLabel?.layer.cornerRadius = 3
            btn.titleLabel?.layer.masksToBounds = true
            btn.setTitle("Apple", for: .normal)
            return btn
        }()
        
        let emailBtn: UIButton = {
            let btn = UIButton(type: .system)
            btn.titleLabel?.font = .systemFont(ofSize: 30, weight: .heavy)
            btn.titleLabel?.adjustsFontSizeToFitWidth = true
            btn.titleLabel?.layer.borderColor = UIColor.separator.cgColor
            btn.titleLabel?.layer.borderWidth = 0.5
            btn.titleLabel?.layer.cornerRadius = 3
            btn.titleLabel?.layer.masksToBounds = true
            btn.setTitle("Email", for: .normal)
            return btn
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUI() {
            let guid = UILayoutGuide()
            addLayoutGuide(guid)
            
            NSLayoutConstraint.activate([
                guid.bottomAnchor.constraint(equalTo: bottomAnchor),
                guid.leftAnchor.constraint(equalTo: leftAnchor),
                guid.rightAnchor.constraint(equalTo: rightAnchor),
                guid.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1 / 3)
            ])
            
            let stackView = UIStackView()
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.spacing = 10
            stackView.distribution = .fillEqually
            stackView.alignment = .fill
            
            stackView.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
            stackView.isLayoutMarginsRelativeArrangement = true
            
            addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.leftAnchor.constraint(equalTo: leftAnchor),
                stackView.rightAnchor.constraint(equalTo: rightAnchor),
                stackView.heightAnchor.constraint(equalTo: guid.heightAnchor, multiplier: 0.5),
                stackView.centerYAnchor.constraint(equalTo: guid.centerYAnchor)
            ])
            
            stackView.addArrangedSubview(appleBtn)
            stackView.addArrangedSubview(emailBtn)
            
            addSubview(titleLabel)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
                titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15),
                titleLabel.topAnchor.constraint(equalTo: topAnchor),
                titleLabel.bottomAnchor.constraint(equalTo: guid.topAnchor)
            ])
        }
        
        private let titleLabel: UILabel = {
            let lb = UILabel()
            lb.font = .systemFont(ofSize: 100, weight: .bold)
            lb.adjustsFontSizeToFitWidth = true
            lb.textAlignment = .center
            lb.text = "Log In"
            return lb
        }()
    }
    
}
