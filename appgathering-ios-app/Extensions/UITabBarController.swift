//
//  UITabBarController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/26/19.
//

import UIKit
extension UITabBarController {
  /**
   Convenience initializer which sets up UINavigationController as well as UITabItems.
   */
  convenience init(navigationRootViewControllers: [UIViewController], animated: Bool = false) {
    self.init()

    let viewControllers = navigationRootViewControllers.map { rootViewController -> UIViewController in
      let viewController = UINavigationController(rootViewController: rootViewController)
      if let tabItemable = rootViewController as? TabItemable {
        tabItemable.configureTabItem(viewController.tabBarItem)
      }
      return viewController
    }
    setViewControllers(viewControllers, animated: animated)
  }
}
