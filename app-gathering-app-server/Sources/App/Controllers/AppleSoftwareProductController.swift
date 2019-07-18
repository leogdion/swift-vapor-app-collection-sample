//
//  File.swift
//
//
//  Created by Leo Dion on 7/17/19.
//

import FluentPostgreSQL
import Vapor

final class AppleSoftwareProductResponse: Content {}

final class AppleSoftwareProductController {
  let urlComponents = URLComponents(string: "https://itunes.apple.com/lookup?")!
  let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    if #available(OSX 10.12, *) {
      decoder.dateDecodingStrategy = .iso8601
    } else {
      // Fallback on earlier versions
    }
    return decoder
  }()

  func create(_ req: Request) throws -> Future<AppleSoftwareProductResponse> {
    let iTunesTrackID = try req.parameters.next(Int.self)
    var urlComponents = self.urlComponents
    urlComponents.queryItems = [URLQueryItem(name: "id", value: iTunesTrackID.description)]
    let futureClient = HTTPClient.connect(hostname: urlComponents.host!, on: req)
    let request = HTTPRequest(method: .GET, url: urlComponents.url!)
    return try futureClient.flatMap { client in
      client.send(request)
    }.flatMap { (response: HTTPResponse) in
      response.body.consumeData(on: req)
    }.map { data in
      try self.jsonDecoder.decode(AppleSearchResult.self, from: data)
    }.map { (result) -> AppleSoftwareProductResponse in
      guard let resultItem = result.results.first else {
        throw Abort(HTTPStatus.notFound)
      }

      // find exists product
      AppleSoftwareProduct.query(on: req).filter(\.trackId == iTunesTrackID).first().map { _ in
      }
      throw Abort(HTTPStatus.notImplemented)
//      let foundAppleSWDeveloper = AppleSoftwareDeveloper.query(on: req).filter(\.artistId == resultItem.artistId).first()

//      throw Abort(HTTPStatus.notImplemented)
//      return AppleSoftwareProductResponse()
      // if exists... update all info
      // if not...

      // find existing apple developer
      // if exists use that for developer
      // update all info
      // if not
      // create a developer
      // create an apple developer
      // create a product
      // create an apple product
    }
  }
}
