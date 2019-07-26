//
//  JSONDecoder.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/26/19.
//

import Foundation

extension JSONDecoder {
  /**
   Decode the result of a  data task into a Decodable object.

    - Parameter type: Target Decoding Type
    - Parameter data: The optional data from the data task to decode.
    - Parameter error: The optional error from the data task.
    - Parameter defaultError: The error to return if there is no data or error.
   */
  func decode<T>(_ type: T.Type, from data: Data?, withError error: Error?, elseError defaultError: Error) -> Result<T, Error> where T: Decodable {
    let result: Result<T, Error>
    if let error = error {
      result = .failure(error)
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