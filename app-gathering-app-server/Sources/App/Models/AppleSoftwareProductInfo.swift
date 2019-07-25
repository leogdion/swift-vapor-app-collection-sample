import Foundation

#if os(Linux) || os(macOS)
  import Vapor
#endif

struct AppleSoftwareProductInfo: Codable {
  let trackId: Int
  let bundleId: String
}
