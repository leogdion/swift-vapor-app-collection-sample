//
//  JSONDecoder.swift
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

extension URLResponse {
  var isNotImplemented: Bool {
    guard let httpResponse = self as? HTTPURLResponse else {
      return false
    }

    return httpResponse.statusCode == 501
  }
}

extension JSONDecoder {
  /**
   Decode the result of a  data task into a Decodable object.

    - Parameter type: Target Decoding Type
    - Parameter data: The optional data from the data task to decode.
    - Parameter error: The optional error from the data task.
    - Parameter defaultError: The error to return if there is no data or error.
   */
  func decode<T>(_ type: T.Type, from data: Data?, withResponse response: URLResponse?, withError error: Error?, elseError defaultError: Error) -> Result<T, Error> where T: Decodable {
    let result: Result<T, Error>
    if let error = error {
      result = .failure(error)
    } else if response?.isNotImplemented == true {
      result = .failure(NotImplmentedError())
    } else if let data = data {
      do {
        let products = try decode(type, from: data)

        result = .success(products)
      } catch {
        result = .failure(error)
      }
    } else {
      result = .failure(defaultError)
    }
    return result
  }
}
