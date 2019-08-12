// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the  Software), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
// THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
