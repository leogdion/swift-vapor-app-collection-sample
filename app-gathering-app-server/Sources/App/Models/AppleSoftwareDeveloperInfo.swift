import Foundation

#if os(Linux) || os(macOS)
import Vapor
#endif

struct AppleSoftwareDeveloperInfo: Codable {
  let artistId: Int
}
