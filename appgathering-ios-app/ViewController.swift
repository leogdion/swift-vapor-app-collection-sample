//
//  ViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/15/19.
//

import UIKit

struct NoDataError : Error {
  
}
struct AppleSearchResult : Codable {
  let results : [AppleSearchResultItem]
}
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
  let sellerUrl : URL
  let releaseDate : Date
}
class ViewController: UITableViewController, UISearchResultsUpdating {

  weak var alertController : UIAlertController!
  weak var busyView : UIView!
  var task : URLSessionDataTask?
  var result : Result<[AppleSearchResultItem], Error>? = .success([AppleSearchResultItem]()) {
    didSet {
      DispatchQueue.main.async {
        
        switch self.result {
        case .none:
          self.busyView.isHidden = false
          break
        case .some(.failure(let error)):
          self.alertController.dismiss(animated: true, completion: nil)
          let alertController = UIAlertController(title: "Error Occured", message: error.localizedDescription, preferredStyle: .alert)
          self.alertController = alertController
          self.present(alertController, animated: true, completion: nil)
        case .some(.success):
          self.busyView.isHidden = false
          self.alertController.dismiss(animated: true) {
            self.alertController = nil
          }
        }
      }
    }
  }
  let baseURLComponents = URLComponents(string: "https://itunes.apple.com/search?entity=software")!
  let jsonDecoder : JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    let activityIndicatorView = UIActivityIndicatorView(style: .large)
    activityIndicatorView.startAnimating()
    let busyView = UIView(frame: self.view.bounds)
    busyView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    busyView.addSubview(activityIndicatorView)
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    activityIndicatorView.centerXAnchor.constraint(equalTo: busyView.centerXAnchor).isActive = true
    activityIndicatorView.centerYAnchor.constraint(equalTo: busyView.centerYAnchor).isActive = true
    self.view.addSubview(busyView)
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search App Store"
    navigationItem.searchController = searchController
    definesPresentationContext = true
  }

  func updateSearchResults(for searchController: UISearchController) {
    guard let term = searchController.searchBar.text else {
      result = .success([AppleSearchResultItem]())
      return
    }
    
    guard !(term.isEmpty) else {
      result = .success([AppleSearchResultItem]())
      return
    }
    
    result = nil
    
    var urlComponents = baseURLComponents
    
    urlComponents.queryItems?.append(URLQueryItem(name: "term", value: term))
    
    let url = urlComponents.url!
    let dataTask = URLSession.shared.dataTask(with: url) { (data, _, error) in
      let result : Result<[AppleSearchResultItem], Error>
      
      if let data = data {
        do {
          let searchResult = try self.jsonDecoder.decode(AppleSearchResult.self, from: data)
          result = .success(searchResult.results)
        } catch let error {
          result = .failure(error)
        }
      } else {
        result = .failure(error ?? NoDataError())
      }
      
      self.result = result
    }
    dataTask.resume()
    self.task = dataTask
  }

}

