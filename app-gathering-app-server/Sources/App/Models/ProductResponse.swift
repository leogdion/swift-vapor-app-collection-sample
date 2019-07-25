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
  extension ProductResponse: Content {}
#endif
