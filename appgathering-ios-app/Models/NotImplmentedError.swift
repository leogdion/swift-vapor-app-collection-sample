//
//  NotImplmentedError.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/26/19.
//

import Foundation
struct NotImplmentedError: LocalizedError {
  var errorDescription: String? {
    return "This API call has not been implemented yet."
  }
}
