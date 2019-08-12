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
    static func future(from product: Product, on connection: DatabaseConnectable) throws -> Future<ProductResponse> {
      let productId = try product.requireID()

      // find the iTunes product metadata
      let appleSoftwareProductF = try product.appleSoftware.query(on: connection).first()

      // find the (required) developer info
      let developerF = product.developer.query(on: connection).first().unwrap(or: Abort(HTTPResponseStatus.internalServerError))

      // find the list of platforms
      let platformNamesF = try product.platforms.query(on: connection).all().map { $0.map { $0.name } }

      // find the iTunes developer metadata
      let appleSoftwareDeveloperF = developerF.flatMap { try $0.appleSoftware.query(on: connection).first() }

      // from the resulting info, create the ProductResponse
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

    /**
     Creates a Future ProductResponse  based on a set of Future info.
     */
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
        let (((product, appleSoftwareProduct), developerResponse), platformNames) = components

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
