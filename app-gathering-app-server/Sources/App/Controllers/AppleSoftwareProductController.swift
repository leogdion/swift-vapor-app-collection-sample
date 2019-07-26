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
  func product(lookupByTrackId iTunesTrackID: Int, on worker: Worker) throws -> Future<AppleSearchResultItem?> {
    var urlComponents = self.urlComponents
    urlComponents.queryItems = [URLQueryItem(name: "id", value: iTunesTrackID.description)]
    let futureClient = HTTPClient.connect(hostname: urlComponents.host!, on: worker)
    let request = HTTPRequest(method: .GET, url: urlComponents.url!)
    return futureClient.flatMap { client in
      client.send(request)
    }.flatMap { (response: HTTPResponse) in
      response.body.consumeData(on: worker)
    }.map { data in
      try self.jsonDecoder.decode(AppleSearchResult.self, from: data)
    }.map {
      $0.results.first
    }
  }

  /**
   Creates or updates a developer in the Database and returns a tuple with the updated developer as well as the iTunes metadata.
   */
  func developer(upsertBasedOn resultItem: AppleSearchResultItem, on req: DatabaseConnectable) -> Future<(Developer, AppleSoftwareDeveloper)> {
    return AppleSoftwareDeveloper.query(on: req).filter(\.artistId == resultItem.artistId).first().flatMap { foundApswDeveloper in
      let apswDeveloperFuture: EventLoopFuture<AppleSoftwareDeveloper>
      let developerFuture: EventLoopFuture<Developer>
      // if the iTunes developer already exists in the database
      if let actualApswDeveloper = foundApswDeveloper {
        apswDeveloperFuture = req.future(actualApswDeveloper)
        // update the developer info
        developerFuture = actualApswDeveloper.developer.get(on: req).flatMap { developer in
          developer.name = resultItem.artistName
          return developer.update(on: req)
        }
      } else {
        // create the new developer
        developerFuture = Developer(name: resultItem.artistName, url: resultItem.sellerUrl).save(on: req)
        // create the new iTunes metadata entry for the developer
        apswDeveloperFuture = developerFuture.map { developer in
          try AppleSoftwareDeveloper(artistId: resultItem.artistId, developerId: developer.requireID())
        }
      }
      return developerFuture.and(apswDeveloperFuture)
    }
  }

  /**
   Creates or updates a product in the Database and returns a tuple with the updated product as well as the iTunes metadata.
   */
  func product(
    upsertBasedOn resultItem: AppleSearchResultItem,
    withiTunesArtist _: AppleSoftwareDeveloper,
    andDeveloper developer: Developer,
    on req: DatabaseConnectable
  ) throws -> Future<(Product, AppleSoftwareProduct)> {
    return AppleSoftwareProduct.query(on: req).filter(\.trackId == resultItem.trackId).first().flatMap { foundApswProduct in
      let productFuture: EventLoopFuture<Product>
      let apswProductFuture: EventLoopFuture<AppleSoftwareProduct>
      // if the iTunes product already exists in the database
      if let actualApswProduct = foundApswProduct {
        actualApswProduct.bundleId = resultItem.bundleId
        // update the itunes info
        apswProductFuture = actualApswProduct.update(on: req)
        // update the product info
        productFuture = actualApswProduct.product.get(on: req).flatMap { product in
          product.name = resultItem.trackName
          product.sourceImageUrl = resultItem.artworkUrl512
          return product.update(on: req)
        }
      } else {
        // create the new prouct
        productFuture = Product(
          developerId: try developer.requireID(),
          name: resultItem.trackName,
          url: resultItem.sellerUrl,
          sourceImageUrl: resultItem.artworkUrl512
        ).save(on: req)
        // create the new iTunes metadata entry for the product
        apswProductFuture = productFuture.flatMap { product in
          try AppleSoftwareProduct(trackId: resultItem.trackId, productId: product.requireID(), bundleId: resultItem.bundleId).save(on: req)
        }
      }
      return productFuture.and(apswProductFuture)
    }
  }

  /**
   Creates or updates the platforms for the product.
   */
  func platforms(
    upsertBasedOn platformsF: EventLoopFuture<[Platform]>,
    forProduct product: Product,
    on req: DatabaseConnectable
  ) throws -> EventLoopFuture<[Platform]> {
    return try product.platforms.pivots(on: req).all()
      .and(platformsF).flatMap { platformsPair in
        let currentProdPlat = platformsPair.0
        let platformsFuture = platformsPair.1
        // find all the old platforms which should be detached from the product
        let deletingProductPlatforms = try currentProdPlat.filter { (productPlatform) -> Bool in
          try !(platformsFuture.contains { (try $0.requireID()) == productPlatform.platformId })
        }
        // find all the new platforms which should be attatched to the product
        let savingProductPlatforms = try platformsFuture.filter { (platform) -> Bool in
          try !(currentProdPlat.contains { $0.platformId == (try platform.requireID()) })
        }.map { platform in
          try ProductPlatform(productId: product.requireID(), platformId: platform.requireID())
        }

        // delete the old platforms and save the new ones
        let deletingFuture = deletingProductPlatforms.map { productPlatform in
          productPlatform.delete(on: req)
        }.flatten(on: req)
        let savingFuture = savingProductPlatforms.map {
          $0.save(on: req)
        }.flatten(on: req)

        // return the finalized list of platforms
        return deletingFuture.and(savingFuture).transform(to: platformsF)
      }
  }

  /**
   Creates or updates the product in the Database based on the iTunes track id for the given user.
   */
  func create(_ req: Request) throws -> Future<ProductResponse> {
    // get the logged in user
    let userF = try req.user()

    // get the track id based on the url parameter
    let iTunesTrackID = try req.parameters.next(Int.self)

    // find the iTunes product
    let iTunesProduct = try product(lookupByTrackId: iTunesTrackID, on: req).unwrap(or: Abort(HTTPStatus.notFound))

    return iTunesProduct.flatMap { (resultItem) -> EventLoopFuture<ProductResponse> in

      // parse the supported platforms
      let platformsFuture = resultItem.supportedDevices.map {
        self.platformController.platform(upsertBasedOnDeviceName: $0, on: req)
      }.flatten(on: req)

      // create or update the developer
      let developerFuture = self.developer(upsertBasedOn: resultItem, on: req)

      // create or update the product
      let productFuture = developerFuture.flatMap { developerPair in
        try self.product(upsertBasedOn: resultItem, withiTunesArtist: developerPair.1, andDeveloper: developerPair.0, on: req)
      }

      // create or update the product's platforms
      let resultingSaves = productFuture.flatMap {
        try self.platforms(upsertBasedOn: platformsFuture, forProduct: $0.0, on: req)
      }

      // create the developer response
      let developerResponseF = DeveloperResponse.future(from: developerFuture)
      return userF.and(productFuture).flatMap { userAndProduct -> Future<Void> in
        // attach the user to the product
        let user = userAndProduct.0
        let product = userAndProduct.1.0
        return user.products.isAttached(product, on: req).flatMap { (isAttached) -> Future<Void> in
          guard !isAttached else {
            return req.future()
          }
          return user.products.attach(product, on: req).transform(to: req.future())
        }

      }.then { _ in
        // return the product response
        ProductResponse.future(from: productFuture, withDeveloper: developerResponseF, withPlatforms: resultingSaves)
      }
    }
  }
}
