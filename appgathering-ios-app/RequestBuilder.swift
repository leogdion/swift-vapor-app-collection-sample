//
//  RequestBuilder.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/25/19.
//

import Foundation

protocol RequestBuilderProtocol {
  func save(baseUrl: URL, forUserWithId userId: UUID)
  func request(withPath path: String, andMethod httpMethod: String) throws -> URLRequest?
}

final class RequestBuilder: RequestBuilderProtocol {
  let jsonEncoder = JSONEncoder()

  var baseUrl: URL? {
    return UserDefaults.standard.url(forKey: "baseUrl")
  }

  var userId: UUID? {
    return UserDefaults.standard.string(forKey: "userId").flatMap(UUID.init)
  }

  func save(baseUrl: URL, forUserWithId userId: UUID) {
    UserDefaults.standard.set(baseUrl, forKey: "baseUrl")
    UserDefaults.standard.set(userId.uuidString, forKey: "userId")
  }

  func request(withPath path: String, andMethod httpMethod: String) throws -> URLRequest? {
    guard var url = self.baseUrl else {
      return nil
    }

    url.appendPathComponent(path)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = httpMethod
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

    if let userId = self.userId {
      urlRequest.addValue(userId.uuidString, forHTTPHeaderField: "X-User-Id")
    }

    return urlRequest
  }

  static var shared: RequestBuilderProtocol = RequestBuilder()
}
