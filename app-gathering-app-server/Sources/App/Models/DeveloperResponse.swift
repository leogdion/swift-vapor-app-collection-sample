import Foundation

#if os(Linux) || os(macOS)
  import Vapor
#endif

struct DeveloperResponse: Codable {
  let id: UUID
  let name: String
  let appleSoftware: AppleSoftwareDeveloperInfo?
}
