//
//  UserViewController.swift
//  SignInProcessor
//
//  Created by Woody Liu on 2023/4/4.
//

import UIKit
import Combine

class UserViewController: UIViewController {
    
    private(set) var user: User!
    
    convenience init(user: User) {
        self.init()
        self.user = user
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    private func setUI() {
        view.backgroundColor = .white
        view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            card.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 2 / 5)
        ])
        card.configure(info: user)
        
        let guid = UILayoutGuide()
        
        view.addLayoutGuide(guid)
        NSLayoutConstraint.activate([
            guid.topAnchor.constraint(equalTo: card.bottomAnchor),
            guid.leftAnchor.constraint(equalTo: view.leftAnchor),
            guid.rightAnchor.constraint(equalTo: view.rightAnchor),
            guid.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let btn = UIButton(type: .system)
        
        btn.setTitle("Log Out", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 40, weight: .heavy)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        view.addSubview(btn)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.centerYAnchor.constraint(equalTo: guid.centerYAnchor),
            btn.leftAnchor.constraint(equalTo: view.leftAnchor),
            btn.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        btn.addTarget(self, action: #selector(logout), for: .touchUpInside)
    }
    
    private let card = Card()
    
    @objc private func logout() {
        self.dismiss(animated: true)
    }
}

fileprivate extension UserViewController {
    
    class Card: UIView {
        
        func configure(info user: User) {
            self.name.text = "NAME: \(user.name ?? "Empty")"
            self.email.text = "EMAIL: " + user.email
            self.date.text = "Login At: " + user.date.ISO8601Format()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUI()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setUI() {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
            stackView.distribution = .fillEqually
            stackView.alignment = .fill
            stackView.spacing = 5
            
            let arr = [name, email, date]
            
            arr.forEach {
                stackView.addArrangedSubview($0)
                $0.font = .systemFont(ofSize: 30, weight: .heavy)
                $0.adjustsFontSizeToFitWidth = true
            }
            
            addSubview(stackView)
            stackView.fillFullInSuperview()
        }
        
        private let name: UILabel = UILabel()
        private let date: UILabel = UILabel()
        private let email: UILabel = UILabel()
    }
    
}
