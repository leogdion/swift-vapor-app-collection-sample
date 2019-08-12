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
//    withDeveloper developer: Developer,
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
