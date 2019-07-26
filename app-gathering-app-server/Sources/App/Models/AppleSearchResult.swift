//
//  AppleSearchResult.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/15/19.
//

import Foundation
/**
 The Codable result returned from an iTunes search query.
 */
struct AppleSearchResult: Codable {
  /**
   The collection of results returned from an iTunes search query.
   */
  let results: [AppleSearchResultItem]
}
