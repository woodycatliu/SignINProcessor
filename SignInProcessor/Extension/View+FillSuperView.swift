//
//  View+FillSuperView.swift
//  SignInProcessor
//
//  Created by Woody Liu on 2023/4/4.
//

import UIKit

extension UIView {
    func fillFullInSuperview(isSafeArea: Bool = true) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: isSafeArea ? superview!.safeAreaLayoutGuide.topAnchor : superview!.topAnchor),
            leftAnchor.constraint(equalTo: isSafeArea ? superview!.safeAreaLayoutGuide.leftAnchor : superview!.leftAnchor),
            rightAnchor.constraint(equalTo: isSafeArea ? superview!.safeAreaLayoutGuide.rightAnchor : superview!.rightAnchor),
            bottomAnchor.constraint(equalTo: isSafeArea ? superview!.safeAreaLayoutGuide.bottomAnchor :  superview!.bottomAnchor)
        ])
    }
}
