//
//  URLResponse.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/26/19.
//

import Foundation

extension URLResponse {
  /**
   Returns true if the URLResponse is an HTTPURLResponse and the status code is 501.
   */
  var isNotImplemented: Bool {
    guard let httpResponse = self as? HTTPURLResponse else {
      return false
    }

    return httpResponse.statusCode == 501
  }
}
