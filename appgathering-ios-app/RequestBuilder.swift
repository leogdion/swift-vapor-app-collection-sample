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

  var userRequest: UserRequest? {
    return UserDefaults.standard.string(forKey: "userId").flatMap { UUID(uuidString: $0) }.map { UserRequest(id: $0) }
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

    if let userRequest = self.userRequest {
      let body = try jsonEncoder.encode(userRequest)
      urlRequest.httpBody = body
    }

    return urlRequest
  }

  static var shared: RequestBuilderProtocol = RequestBuilder()
}
