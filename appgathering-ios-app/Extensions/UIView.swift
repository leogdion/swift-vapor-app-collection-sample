//
//  UIView.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/26/19.
//

import UIKit

extension UIView {
  func addBusyView() -> UIView {
    let activityIndicatorView = UIActivityIndicatorView(style: .large)
    activityIndicatorView.startAnimating()
    let busyView = UIView(frame: bounds)
    busyView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    busyView.addSubview(activityIndicatorView)
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    activityIndicatorView.centerXAnchor.constraint(equalTo: busyView.centerXAnchor).isActive = true
    activityIndicatorView.centerYAnchor.constraint(equalTo: busyView.centerYAnchor).isActive = true
    addSubview(busyView)
    return busyView
  }
}
