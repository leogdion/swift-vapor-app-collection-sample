import Foundation

#if os(Linux) || os(macOS)
  import Vapor
#endif

struct DeveloperResponse: Codable {
  let id: UUID
  let name: String
  let appleSoftware: AppleSoftwareDeveloperInfo?
}

#if os(Linux) || os(macOS)
  extension DeveloperResponse {
    static func future(from developerPair: Future<(Developer, AppleSoftwareDeveloper)>) -> Future<DeveloperResponse> {
      return developerPair.map { developer, appleSoftwareDeveloper in
        let apswDeveloperInfo = AppleSoftwareDeveloperInfo(artistId: appleSoftwareDeveloper.artistId)
        return DeveloperResponse(id: try developer.requireID(), name: developer.name, appleSoftware: apswDeveloperInfo)
      }
    }
  }
#endif
