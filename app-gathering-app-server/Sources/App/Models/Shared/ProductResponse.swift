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
    /**
     Creates a Future ProductResponse  based on a Product.
     */
//    static func future(from product: Product, on connection: DatabaseConnectable) throws -> Future<ProductResponse> {
//    }

    /**
     Creates a Future ProductResponse  based on a set of Future info.
     */
//    static func future(
//      from productPair: Future<(Product, AppleSoftwareProduct)>,
//      withDeveloper developerResponseF: Future<DeveloperResponse>,
//      withPlatforms platformsF: Future<[Platform]>
//    ) -> Future<ProductResponse> {
//    }
  }
#endif
