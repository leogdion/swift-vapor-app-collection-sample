//
//  ViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/15/19.
//

import UIKit

protocol TabItemable {
  func configureTabItem(_ tabItem: UITabBarItem)
}

extension UITabBarController {
  convenience init(navigationRootViewControllers: [UIViewController], animated: Bool = false) {
    self.init()

    let viewControllers = navigationRootViewControllers.map { rootViewController -> UIViewController in
      let viewController = UINavigationController(rootViewController: rootViewController)
      if let tabItemable = rootViewController as? TabItemable {
        tabItemable.configureTabItem(viewController.tabBarItem)
      }
      return viewController
    }
    setViewControllers(viewControllers, animated: animated)
  }
}

class AppStoreSearchResultTableViewController: UITableViewController, UISearchResultsUpdating, TabItemable {
  let reuseIdentifier = "reuseIdentifier"
  weak var alertController: UIAlertController?
  weak var busyView: UIView!
  var firstLogin = true
  var task: URLSessionDataTask?
  var result: Result<[AppleSearchResultItem], Error>? = .success([AppleSearchResultItem]()) {
    didSet {
      DispatchQueue.main.async {
        switch self.result {
        case .none:
          self.busyView.isHidden = false
        case let .some(.failure(error)):
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
  let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    let activityIndicatorView = UIActivityIndicatorView(style: .large)
    activityIndicatorView.startAnimating()
    let busyView = UIView(frame: view.bounds)
    busyView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    busyView.addSubview(activityIndicatorView)
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
    activityIndicatorView.centerXAnchor.constraint(equalTo: busyView.centerXAnchor).isActive = true
    activityIndicatorView.centerYAnchor.constraint(equalTo: busyView.centerYAnchor).isActive = true
    view.addSubview(busyView)
    self.busyView = busyView
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search App Store"
    navigationItem.searchController = searchController
    definesPresentationContext = true

    tableView.register(UINib(nibName: "AppStoreSearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
  }

  override func viewDidAppear(_ animated: Bool) {
    if firstLogin {
      let loginViewController = LoginViewController()
      loginViewController.modalPresentationStyle = .fullScreen
      navigationController?.present(loginViewController, animated: animated, completion: { self.firstLogin = false })
    }
  }

  func updateSearchResults(for searchController: UISearchController) {
    guard let term = searchController.searchBar.text else {
      result = .success([AppleSearchResultItem]())
      return
    }

    guard !term.isEmpty else {
      result = .success([AppleSearchResultItem]())
      return
    }

    result = nil

    var urlComponents = baseURLComponents

    urlComponents.queryItems?.append(URLQueryItem(name: "term", value: term))

    let url = urlComponents.url!

    let dataTask = URLSession.shared.dataTask(with: url) { data, _, error in
      let result: Result<[AppleSearchResultItem], Error>

      if let data = data {
        do {
          let searchResult = try self.jsonDecoder.decode(AppleSearchResult.self, from: data)
          result = .success(searchResult.results)
        } catch {
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
    task = dataTask
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return (try? result?.get())?.count ?? 0
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
    // loadArtwork(fromUrl: item.artworkUrl512, forCellAtIndexPath: indexPath)

    searchResultCell.nameLabel.text = item.trackName
    searchResultCell.subtitleLabel.text = "by \(item.sellerName)"

    return searchResultCell
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let searchItem = (try? result?.get())?[indexPath.row] else {
      return
    }

    guard let request =
      try? RequestBuilder.shared.request(withPath: "/iTunesProducts/\(searchItem.trackId)", andMethod: "POST") else {
      return
    }

    busyView.isHidden = false
    URLSession.shared.dataTask(with: request) { _, _, error in
      guard error == nil else {
        return
      }

      DispatchQueue.main.async {
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.busyView.isHidden = true
      }

      NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AppCollectionUpdated"), object: nil)
    }.resume()
  }

  override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
    return 90.0
  }

  func configureTabItem(_ tabItem: UITabBarItem) {
    tabItem.title = "Search"
    tabItem.image = UIImage(systemName: "magnifyingglass")
  }
}
