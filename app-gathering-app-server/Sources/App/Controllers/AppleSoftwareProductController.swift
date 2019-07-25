//
//  File.swift
//
//
//  Created by Leo Dion on 7/17/19.
//

import FluentPostgreSQL
import Vapor


extension DeveloperResponse {
  static func future(from developerPair: Future<(Developer, AppleSoftwareDeveloper)>) -> Future<DeveloperResponse> {
    return developerPair.map { developer, appleSoftwareDeveloper in
      let apswDeveloperInfo = AppleSoftwareDeveloperInfo(artistId: appleSoftwareDeveloper.artistId)
      return DeveloperResponse(id: try developer.requireID(), name: developer.name, appleSoftware: apswDeveloperInfo)
    }
  }
}

extension ProductResponse {
  static func future(from product: Product, on connection: DatabaseConnectable) throws -> Future<ProductResponse> {
    let productId = try product.requireID()
    let appleSoftwareProductF = try product.appleSoftware.query(on: connection).first()
    let developerF = product.developer.query(on: connection).first().unwrap(or: Abort(HTTPResponseStatus.internalServerError))

    let platformNamesF = try product.platforms.query(on: connection).all().map { $0.map { $0.name } }

    let appleSoftwareDeveloperF = try developerF.flatMap { try $0.appleSoftware.query(on: connection).first() }

    return developerF.and(appleSoftwareProductF.and(appleSoftwareDeveloperF)).and(platformNamesF).map { components in
      let ((developer, (appleSoftwareProduct, appleSoftwareDeveloper)), platformNames) = components

      let appleSoftwareDeveloperInfo =
        appleSoftwareDeveloper.map { AppleSoftwareDeveloperInfo(artistId: $0.artistId) }
      let appleSoftwareProductInfo = appleSoftwareProduct.map {
        AppleSoftwareProductInfo(trackId: $0.trackId, bundleId: $0.bundleId)
      }
      let developerResponse = try DeveloperResponse(id: developer.requireID(), name: developer.name, appleSoftware: appleSoftwareDeveloperInfo)

      return ProductResponse(id: productId, name: product.name, url: product.url, sourceImageUrl: product.sourceImageUrl, platforms: platformNames, developer: developerResponse, appleSoftware: appleSoftwareProductInfo)
    }
  }

  static func future(from productPair: Future<(Product, AppleSoftwareProduct)>, withDeveloper developerResponseF: Future<DeveloperResponse>, withPlatforms platformsF: Future<[Platform]>) -> Future<ProductResponse> {
    let platformNamesF = platformsF.map {
      $0.map {
        $0.name
      }
    }

    return productPair.and(developerResponseF).and(platformNamesF).map { components in
      let product = components.0.0.0
      let appleSoftwareProduct = components.0.0.1
      let developerResponse = components.0.1
      let platformNames = components.1

      let productId = try product.requireID()
      let appleSoftware = AppleSoftwareProductInfo(trackId: appleSoftwareProduct.trackId, bundleId: appleSoftwareProduct.bundleId)

      return ProductResponse(id: productId, name: product.name, url: product.url, sourceImageUrl: product.sourceImageUrl, platforms: platformNames, developer: developerResponse, appleSoftware: appleSoftware)
    }
  }
}




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

  func developer(basedOnProduct resultItem: AppleSearchResultItem, on req: DatabaseConnectable) -> Future<(Developer, AppleSoftwareDeveloper)> {
    return AppleSoftwareDeveloper.query(on: req).filter(\.artistId == resultItem.artistId).first().flatMap {
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
  }

  func product(upsertBasedOn resultItem: AppleSearchResultItem, withiTunesArtist _: AppleSoftwareDeveloper, andDeveloper developer: Developer, on req: DatabaseConnectable) throws -> Future<(Product, AppleSoftwareProduct)> {
    return AppleSoftwareProduct.query(on: req).filter(\.trackId == resultItem.trackId).first().flatMap { foundApswProduct in
      let productFuture: EventLoopFuture<Product>
      let apswProductFuture: EventLoopFuture<AppleSoftwareProduct>
      if let actualApswProduct = foundApswProduct {
        actualApswProduct.bundleId = resultItem.bundleId
        apswProductFuture = actualApswProduct.save(on: req)
        productFuture = actualApswProduct.product.get(on: req).flatMap { product in
          product.name = resultItem.trackName
          product.sourceImageUrl = resultItem.artworkUrl512
          return product.save(on: req)
        }
      } else {
        productFuture = Product(developerId: try developer.requireID(), name: resultItem.trackName, sourceImageUrl: resultItem.artworkUrl512).save(on: req)
        apswProductFuture = productFuture.flatMap { product in
          try AppleSoftwareProduct(trackId: resultItem.trackId, productId: product.requireID(), bundleId: resultItem.bundleId).save(on: req)
        } //
      }
      return productFuture.and(apswProductFuture)
    }
  }

  func platforms(upsertBasedOn platformsF: EventLoopFuture<[Platform]>, forProduct product: Product, on req: DatabaseConnectable) throws -> EventLoopFuture<[Platform]> {
    return try product.platforms.pivots(on: req).all()
      .and(platformsF).flatMap {
        platformsPair in
        let currentProdPlat = platformsPair.0
        let platformsFuture = platformsPair.1
        let deletingProductPlatforms = try currentProdPlat.filter { (productPlatform) -> Bool in
          try !(platformsFuture.contains { (try $0.requireID()) == productPlatform.platformId })
        }
        let savingProductPlatforms = try platformsFuture.filter { (platform) -> Bool in
          try !(currentProdPlat.contains { $0.platformId == (try platform.requireID()) })
        }.map { platform in
          try ProductPlatform(productId: product.requireID(), platformId: platform.requireID())
        }

        let deletingFuture = deletingProductPlatforms.map { productPlatform in
          productPlatform.delete(on: req)
        }.flatten(on: req)
        let savingFuture = savingProductPlatforms.map {
          $0.save(on: req)
        }.flatten(on: req)

        return deletingFuture.and(savingFuture).transform(to: platformsF)
      }
  }

  func create(_ req: Request) throws -> Future<ProductResponse> {
    let userFuture = try req.content.decode(UserRequest.self)

    let iTunesTrackID = try req.parameters.next(Int.self)
    let iTunesProduct = try product(lookupByTrackId: iTunesTrackID, on: req).unwrap(or: Abort(HTTPStatus.notFound))

    return iTunesProduct.flatMap { (resultItem) -> EventLoopFuture<ProductResponse> in

      let platformsFuture = resultItem.supportedDevices.map {
        self.platformController.platform(upsertBasedOnDeviceName: $0, on: req)
      }.flatten(on: req)

      // add platforms if not exist
      // find existing product
      let developerFuture = self.developer(basedOnProduct: resultItem, on: req)

      let productFuture = developerFuture.flatMap { developerPair in
        try self.product(upsertBasedOn: resultItem, withiTunesArtist: developerPair.1, andDeveloper: developerPair.0, on: req)
      }

      let resultingSaves: Future<[Platform]>
      resultingSaves = productFuture.flatMap {
        try self.platforms(upsertBasedOn: platformsFuture, forProduct: $0.0, on: req)
      }
      let developerResponseF = DeveloperResponse.future(from: developerFuture)
      let userProductF = userFuture.map { userRequest in
        User.find(userRequest.id, on: req).unwrap(or: Abort(HTTPResponseStatus.unauthorized))
          .and(productFuture).flatMap { userAndProduct -> Future<UserProduct> in
            let user = userAndProduct.0
            let product = userAndProduct.1.0
            return user.products.attach(product, on: req)
          }
      }
      return ProductResponse.future(from: productFuture, withDeveloper: developerResponseF, withPlatforms: platformsFuture)
    }
  }
}
