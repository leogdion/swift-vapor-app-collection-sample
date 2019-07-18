//
//  File.swift
//
//
//  Created by Leo Dion on 7/17/19.
//

import FluentPostgreSQL
import Vapor

struct DeveloperResponse: Content {
  let id: UUID
  let name: String
  let appleSoftware: AppleSoftwareDeveloperInfo?
}

struct ProductResponse: Content {
  let id: UUID
  let name: String
  let url: URL?
  let sourceImageUrl: URL?
  let platforms: [String]
  let developer: DeveloperResponse
  let appleSoftware: AppleSoftwareProductInfo?
}

struct AppleSoftwareProductInfo: Content {
  let trackId: Int
  let bundleId: String
}

struct AppleSoftwareDeveloperInfo: Content {
  let artistId: Int
}

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

  func create(_ req: Request) throws -> Future<ProductResponse> {
    let userFuture = try req.content.decode(User.self)
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
    }.flatMap { (result) -> EventLoopFuture<ProductResponse> in
      guard let resultItem = result.results.first else {
        throw Abort(HTTPStatus.notFound)
      }

      let platformsFuture = resultItem.supportedDevices.map { (apswDeviceName: String) -> EventLoopFuture<Platform> in

        let deviceNames = Set<String>(apswDeviceName.components(separatedBy: "-"))
        let deviceName = deviceNames.count == 1 ? deviceNames.first! : apswDeviceName
        return Platform.query(on: req).filter(\.name == deviceName).first().flatMap { foundPlatform in
          if let platform = foundPlatform {
            return req.future(platform)
          } else {
            return Platform(name: deviceName).save(on: req)
          }
        }
      }.flatten(on: req)

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

        let currentProdPlat = productFuture.flatMap { (product: Product) in
          try product.platforms.pivots(on: req).all()
        }

        return currentProdPlat.and(platformsFuture).and(productFuture.and(apswProductFuture)).flatMap { result -> EventLoopFuture<ProductResponse> in
          let currentProductPlatforms = result.0.0
          let updatingPlatforms = result.0.1
          let product = result.1.0
          let apswProduct = result.1.1
          let deletingProductPlatforms = try currentProductPlatforms.filter { (productPlatform) -> Bool in
            try !(updatingPlatforms.contains { (try $0.requireID()) == productPlatform.platformId })
          }
          let savingProductPlatforms = try updatingPlatforms.filter { (platform) -> Bool in
            try !(currentProductPlatforms.contains { $0.platformId == (try platform.requireID()) })
          }.map { platform in
            try ProductPlatform(productId: product.requireID(), platformId: platform.requireID())
          }
          let deletingFuture = deletingProductPlatforms.map { productPlatform in
            productPlatform.delete(on: req)
          }.flatten(on: req)
          let savingFuture = savingProductPlatforms.map {
            $0.save(on: req)
          }.flatten(on: req)

          return userFuture.then { user in
            user.products.attach(product, on: req)
          }.and(savingFuture).and(deletingFuture).map {
            _ in

            let developerResponse: DeveloperResponse
            let productResponse: ProductResponse
            let apswProductInfo: AppleSoftwareProductInfo
            let apswDeveloperInfo: AppleSoftwareDeveloperInfo
            apswProductInfo = AppleSoftwareProductInfo(trackId: apswProduct.trackId, bundleId: apswProduct.bundleId)
            apswDeveloperInfo = AppleSoftwareDeveloperInfo(artistId: apswDeveloper.artistId)
            developerResponse = DeveloperResponse(id: try developer.requireID(), name: developer.name, appleSoftware: apswDeveloperInfo)
            return try ProductResponse(id: product.requireID(), name: product.name, url: product.url, sourceImageUrl: product.sourceImageUrl, platforms: updatingPlatforms.map { $0.name }, developer: developerResponse, appleSoftware: apswProductInfo)
          }
        }
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
