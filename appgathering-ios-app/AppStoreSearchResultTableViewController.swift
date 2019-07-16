//
//  ViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/15/19.
//

import UIKit



class AppStoreSearchResultTableViewController: UITableViewController, UISearchResultsUpdating {

  let reuseIdentifier = "reuseIdentifier"
  weak var alertController : UIAlertController?
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
          self.alertController?.dismiss(animated: true, completion: nil)
          let alertController = UIAlertController(title: "Error Occured", message: error.localizedDescription, preferredStyle: .alert)
          self.alertController = alertController
          self.present(alertController, animated: true, completion: nil)
        case .some(.success):
          self.busyView.isHidden = true
          self.alertController?.dismiss(animated: true) {
            self.alertController = nil
          }
        }
        self.tableView.reloadData()
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
    self.busyView = busyView
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search App Store"
    navigationItem.searchController = searchController
    definesPresentationContext = true
    
    self.tableView.register(UINib(nibName: "AppStoreSearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
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
    
    DispatchQueue.global().async {
      dataTask.resume()
      
    }
    self.task = dataTask
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return (try? self.result?.get())?.count ?? 0
  }
  
  func loadArtwork(fromUrl artworkURL: URL, forCellAtIndexPath indexPath: IndexPath) {
    DispatchQueue.global().async {
      guard let searchResultCell = self.tableView.cellForRow(at: indexPath) as? AppStoreSearchResultTableViewCell else {
        return
      }
          guard let data = try? Data(contentsOf: artworkURL) else {
            return
          }
      
          guard let image = UIImage(data: data) else {
            return
          }
      
      DispatchQueue.main.async {
          searchResultCell.artworkView.image = image
      }
      
    }

  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
    
    guard let searchResultCell = cell as? AppStoreSearchResultTableViewCell else {
      return cell
    }
    
    guard let item = (try? self.result?.get())?[indexPath.row] else {
      return searchResultCell
    }
    
    DispatchQueue.global().async {
      guard let data = try? Data(contentsOf: item.artworkUrl512) else {
        return
      }
      DispatchQueue.main.async {
        searchResultCell.artworkView.image = UIImage(data: data)
      }
    }
    //loadArtwork(fromUrl: item.artworkUrl512, forCellAtIndexPath: indexPath)

    searchResultCell.nameLabel.text = item.trackName
    searchResultCell.subtitleLabel.text = "by \(item.sellerName)"
    
    return searchResultCell
  }
  
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 90.0
  }
}

