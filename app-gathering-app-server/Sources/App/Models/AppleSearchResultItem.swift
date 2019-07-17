//
//  AppleSearchResultItem.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/15/19.
//

import Foundation
struct AppleSearchResultItem : Codable {
  let artistId : Int
  let artistName : String
  let artworkUrl512 : URL
  let bundleId : String
  let description : String
  let minimumOsVersion : String
  let supportedDevices : [String]
  let trackId : Int
  let trackName : String
  let version : String
  let sellerName : String
  let sellerUrl : URL?
  let releaseDate : Date
}
