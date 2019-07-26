import Foundation

#if os(Linux) || os(macOS)
  import Vapor
#endif

struct ProductResponse: Codable {
  let id: UUID
  let name: String
  let url: URL?
  let sourceImageUrl: URL?
  let platforms: [String]
  let developer: DeveloperResponse
  let appleSoftware: AppleSoftwareProductInfo?
}

#if os(Linux) || os(macOS)
  extension ProductResponse: Content {
    static func future(from product: Product, on connection: DatabaseConnectable) throws -> Future<ProductResponse> {
      let productId = try product.requireID()
      let appleSoftwareProductF = try product.appleSoftware.query(on: connection).first()
      let developerF = product.developer.query(on: connection).first().unwrap(or: Abort(HTTPResponseStatus.internalServerError))

      let platformNamesF = try product.platforms.query(on: connection).all().map { $0.map { $0.name } }

      let appleSoftwareDeveloperF = developerF.flatMap { try $0.appleSoftware.query(on: connection).first() }

      return developerF.and(appleSoftwareProductF.and(appleSoftwareDeveloperF)).and(platformNamesF).map { components in
        let ((developer, (appleSoftwareProduct, appleSoftwareDeveloper)), platformNames) = components

        let appleSoftwareDeveloperInfo =
          appleSoftwareDeveloper.map { AppleSoftwareDeveloperInfo(artistId: $0.artistId) }
        let appleSoftwareProductInfo = appleSoftwareProduct.map {
          AppleSoftwareProductInfo(trackId: $0.trackId, bundleId: $0.bundleId)
        }
        let developerResponse = try DeveloperResponse(id: developer.requireID(), name: developer.name, appleSoftware: appleSoftwareDeveloperInfo)

        return ProductResponse(
          id: productId,
          name: product.name,
          url: product.url,
          sourceImageUrl: product.sourceImageUrl,
          platforms: platformNames,
          developer: developerResponse,
          appleSoftware: appleSoftwareProductInfo
        )
      }
    }

    static func future(
      from productPair: Future<(Product, AppleSoftwareProduct)>,
      withDeveloper developerResponseF: Future<DeveloperResponse>,
      withPlatforms platformsF: Future<[Platform]>
    ) -> Future<ProductResponse> {
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

        return ProductResponse(
          id: productId,
          name: product.name,
          url: product.url,
          sourceImageUrl: product.sourceImageUrl,
          platforms: platformNames,
          developer: developerResponse,
          appleSoftware: appleSoftware
        )
      }
    }
  }
#endif
