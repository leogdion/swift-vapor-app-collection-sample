//
//  PlatformController.swift
//  App
//
//  Created by Leo Dion on 7/24/19.
//

import FluentPostgreSQL
import Foundation
import Vapor

final class PlatformController {
  func platform(upsertBasedOnDeviceName apswDeviceName: String, on database: DatabaseConnectable) -> Future<Platform> {
    let deviceNames = Set<String>(apswDeviceName.components(separatedBy: "-"))
    let deviceName = (deviceNames.count == 1 ? deviceNames.first : apswDeviceName) ?? apswDeviceName

    return Platform.query(on: database).filter(\.name == deviceName).first().flatMap { foundPlatform -> Future<Platform> in
      if let platform = foundPlatform {
        return database.future(platform)
      } else {
        return Platform(name: deviceName).save(on: database)
      }
    }
  }
}
