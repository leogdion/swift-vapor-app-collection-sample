//
//  RequestBuilder.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/25/19.
//

import Foundation

protocol RequestBuilderProtocol {
  var jsonEncoder: JSONEncoder { get }

  func save(baseUrl: URL, forUserWithId userId: UUID)

  func request(usingBaseUrl baseUrl: URL?, withPath path: String, andMethod httpMethod: String, andData data: Data?) throws -> URLRequest?
}

extension RequestBuilderProtocol {
  func request(usingBaseUrl baseUrl: URL? = nil, withPath path: String, andMethod httpMethod: String, andData data: Data? = nil) throws -> URLRequest? {
    return try request(usingBaseUrl: baseUrl, withPath: path, andMethod: httpMethod, andData: data)
  }

  func request(withPath path: String, andMethod httpMethod: String) throws -> URLRequest? {
    return try request(usingBaseUrl: nil, withPath: path, andMethod: httpMethod, andData: nil)
  }

  func request<T: Encodable>(usingBaseUrl baseUrl: URL? = nil, withPath path: String, andMethod httpMethod: String, andBody body: T) throws -> URLRequest? {
    let data = try jsonEncoder.encode(body)
    return try request(usingBaseUrl: baseUrl, withPath: path, andMethod: httpMethod, andData: data)
  }
}

struct RequestBuilder: RequestBuilderProtocol {
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

  func request(usingBaseUrl baseUrl: URL?, withPath path: String, andMethod httpMethod: String, andData data: Data?) throws -> URLRequest? {
    guard var url = baseUrl ?? self.baseUrl else {
      return nil
    }

    url.appendPathComponent(path)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = httpMethod
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // set the X-User-Id for a simpistic non-secure way of doing authentication
    if let userId = self.userId {
      urlRequest.addValue(userId.uuidString, forHTTPHeaderField: "X-User-Id")
    }

    urlRequest.httpBody = data

    return urlRequest
  }

  static var shared: RequestBuilderProtocol = RequestBuilder()
}
