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
    }.flatMap { (result) -> EventLoopFuture<AppleSoftwareProductResponse> in
      guard let resultItem = result.results.first else {
        throw Abort(HTTPStatus.notFound)
      }

      // add platforms if not exist
      // find existing product
      let devFuture: EventLoopFuture<(Developer, AppleSoftwareDeveloper)> = AppleSoftwareDeveloper.query(on: req).filter(\.artistId == resultItem.artistId).first().flatMap {
        foundApswDeveloper in
        let apswDeveloperFuture: EventLoopFuture<AppleSoftwareDeveloper>
        let developerFuture: EventLoopFuture<Developer>
        if let actualApswDeveloper = foundApswDeveloper {
          apswDeveloperFuture = req.future(actualApswDeveloper)
          developerFuture = actualApswDeveloper.developer.get(on: req).flatMap { developer in
            developer.name = resultItem.artistName
            return developer.save(on: req)
          }
        } else {
          developerFuture = Developer(name: resultItem.artistName, url: resultItem.sellerUrl).save(on: req)
          apswDeveloperFuture = developerFuture.map { developer in
            try AppleSoftwareDeveloper(artistId: resultItem.artistId, developerId: developer.requireID())
          }
        }
        return developerFuture.and(apswDeveloperFuture)
      }

      return AppleSoftwareProduct.query(on: req).filter(\.trackId == resultItem.trackId).first().and(devFuture).flatMap { result in
        let foundApswProduct = result.0
        let developer = result.1.0
        let apswDeveloper = result.1.1
        let product: EventLoopFuture<Product>
        if let actualApswProduct = foundApswProduct {} else {}
        return req.future(AppleSoftwareProductResponse())
      }
      // check apple product exists
      //  if apple product exists
      //    check apple developer exists
      //      if apple developer exists
      //        update apple developer
      //        update developer
      //      if apple developer does not exist
      //        create developer
      //        create apple developer
      //    update apple product
      //    update product
      //  if apple product does not exist
      //    check apple developer exists
      //      if apple developer exists
      //        update apple developer
      //        update developer
      //      if apple developer does not exist
      //        create developer
      //        create apple developer
      //    create product
      //    create apple product

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
