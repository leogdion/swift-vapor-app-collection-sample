//
//  File.swift
//
//
//  Created by Leo Dion on 7/17/19.
//

import FluentPostgreSQL
import Vapor

final class AppleSoftwareProductController {
  let platformController: PlatformController
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

  init(platformController: PlatformController) {
    self.platformController = platformController
  }

  /**
   Looks up product from iTunes
   */
//  func product(lookupByTrackId iTunesTrackID: Int, on worker: Worker) throws -> Future<AppleSearchResultItem?> {
//  }

  /**
   Creates or updates a developer in the Database and returns a tuple with the updated developer as well as the iTunes metadata.
   */
//  func developer(upsertBasedOn resultItem: AppleSearchResultItem, on req: DatabaseConnectable) -> Future<(Developer, AppleSoftwareDeveloper)> {
//  }

  /**
   Creates or updates a product in the Database and returns a tuple with the updated product as well as the iTunes metadata.
   */
//  func product(
//    upsertBasedOn resultItem: AppleSearchResultItem,
//    withiTunesArtist _: AppleSoftwareDeveloper,
//    andDeveloper developer: Developer,
//    on req: DatabaseConnectable
//  ) throws -> Future<(Product, AppleSoftwareProduct)> {
//  }

  /**
   Creates or updates the platforms for the product.
   */
//  func platforms(
//    upsertBasedOn platformsF: EventLoopFuture<[Platform]>,
//    forProduct product: Product,
//    on req: DatabaseConnectable
//  ) throws -> EventLoopFuture<[Platform]> {
//  }

  /**
   Creates or updates the product in the Database based on the iTunes track id for the given user.
   */
  func create(_ req: Request) throws -> Future<ProductResponse> {
    // get the logged in user
    let userF = try req.user()

    // get the track id based on the url parameter
    let iTunesTrackID = try req.parameters.next(Int.self)

    // TODO:find the iTunes product

      // TODO: parse the supported platforms

      // TODO: create or update the developer

      // TODO: create or update the product

      // TODO: create or update the product's platforms

      // TODO: create the developer response
      
      // TODO: attach the user to the product
      
      // TODO: return the product response
    
    throw Abort(.notImplemented)
  }
}
