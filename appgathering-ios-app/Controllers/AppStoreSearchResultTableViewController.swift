// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the  Software), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
// THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#if !targetEnvironment(simulator)
  import StoreKit
#endif

import UIKit

/**
 UITableViewController for displaying the search results from iTunes.
 */
class AppStoreSearchResultTableViewController: UITableViewController {
  /**
   Reuse Identifier for each UITableViewCell.
   */
  static let reuseIdentifier = "reuseIdentifier"

  /**
   JSON Decoder for data from api.
   */
  static let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()

  /**
   The base url components for building a query to iTunes search.
   */
  static let baseURLComponents = URLComponents(string: "https://itunes.apple.com/search?entity=software")!

  /**
   Active Data Task.
   */
  var dataTask: URLSessionDataTask?

  /**
   Access to the activity indicator and overlay.
   */
  weak var busyView: UIView!

  /**
   Current error UIAlertController
   */
  weak var alertController: UIAlertController?

  /**
   Tasks whether the user needs to login.
   */
  var firstLogin = true

  /**
   Decoded result from api call or error.
   */
  var result: Result<[AppleSearchResultItem], Error>? = .success([AppleSearchResultItem]()) {
    didSet {
      DispatchQueue.main.async {
        switch self.result {
        case .none:
          // show the busy indicator when no result yet
          self.busyView.isHidden = false
        case let .some(.failure(error)):
          // display alert with error
          self.alertController?.dismiss(animated: true, completion: nil)
          let alertController = UIAlertController(title: "Error Occured", message: error.localizedDescription, preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
          self.alertController = alertController
          self.present(alertController, animated: true, completion: nil)
        case .some(.success):
          // hide the activity indicator and dismiss the alert
          self.busyView.isHidden = true
          self.alertController?.dismiss(animated: true) {
            self.alertController = nil
          }
        }
        self.tableView.reloadData()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // add a busy overlay
    busyView = view.addBusyView()

    // setup the search controller
    navigationItem.searchController = setupSearchController()
    definesPresentationContext = true

    // register the UITableViewCell
    let cellNib = UINib(nibName: "AppStoreSearchResultTableViewCell", bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: AppStoreSearchResultTableViewController.reuseIdentifier)
  }

  /**
   Setup the search controller.
   */
  func setupSearchController() -> UISearchController {
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search App Store"
    return searchController
  }

  // StoreKit disabled on simulator since there's no App Store
  #if !targetEnvironment(simulator)

    /**
     Open the App Store Product View for the currently selected product.
     */
    func openAppStore(_: UIAlertAction) {
      guard let indexPath = self.tableView.indexPathForSelectedRow else {
        return
      }

      guard let searchItem = (try? result?.get())?[indexPath.row] else {
        return
      }

      let storeController = SKStoreProductViewController()
      storeController.delegate = self
      storeController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: searchItem.trackId]) { loaded, _ in
        if loaded {
          self.present(storeController, animated: true, completion: nil)
        }
      }
    }
  #endif

  /**
   Login if this is the first time the view is available.
   */
  override func viewDidAppear(_ animated: Bool) {
    if firstLogin {
      let loginViewController = LoginViewController()
      loginViewController.modalPresentationStyle = .fullScreen
      navigationController?.present(loginViewController, animated: animated, completion: { self.firstLogin = false })
    }
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return (try? result?.get())?.count ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // dequeue the UITableViewCell
    let cell = tableView.dequeueReusableCell(withIdentifier: AppStoreSearchResultTableViewController.reuseIdentifier, for: indexPath)

    // try to cast as AppStoreSearchResultTableViewCell
    guard let searchResultCell = cell as? AppStoreSearchResultTableViewCell else {
      return cell
    }

    // try to get the search item based on the indexPath
    guard let item = (try? self.result?.get())?[indexPath.row] else {
      return searchResultCell
    }

    // if the product has an image, load the image into the view
    DispatchQueue.global().async {
      guard let data = try? Data(contentsOf: item.artworkUrl512) else {
        return
      }
      DispatchQueue.main.async {
        searchResultCell.artworkView.image = UIImage(data: data)
      }
    }

    searchResultCell.nameLabel.text = item.trackName
    searchResultCell.subtitleLabel.text = "by \(item.sellerName)"

    return searchResultCell
  }

  /**
   Removes  the currently selected product from the user's app list.
   */
  func addAction(_: UIAlertAction) {
    // get the indexPath
    guard let indexPath = self.tableView.indexPathForSelectedRow else {
      return
    }

    guard let searchItem = (try? result?.get())?[indexPath.row] else {
      return
    }
    guard let request =
      try? RequestBuilder.shared.request(withPath: "/iTunesProducts/\(searchItem.trackId)", andMethod: "POST") else {
      return
    }
    navigationItem.searchController?.isActive = false
    busyView.isHidden = false
    URLSession.shared.dataTask(with: request) { _, _, error in
      guard error == nil else {
        return
      }

      NotificationCenter.default.post(name: NotificationNames.AppCollectionUpdated, object: nil)

      DispatchQueue.main.async {
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.busyView.isHidden = true
      }
    }.resume()
  }

  /**
   Displays an action sheet when the user selects a product.
   */
  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let searchItem = (try? result?.get())?[indexPath.row] else {
      return
    }

    let alertController = UIAlertController(title: searchItem.trackName, message: "What would you like to do?", preferredStyle: .actionSheet)

    alertController.addAction(UIAlertAction(title: "Add App", style: .destructive, handler: addAction))
    // If the app has a web site, allow the user to open the web site url.

    if let url = searchItem.sellerUrl {
      alertController.addAction(UIAlertAction(title: "Open Website", style: .default, handler: { _ in
        UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey: Any](), completionHandler: { _ in
          self.tableView.deselectRow(at: indexPath, animated: true)
        })
      }))
    }

    #if !targetEnvironment(simulator)
      // allow the user to open the app store page
      alertController.addAction(UIAlertAction(title: "Open App Store", style: .default, handler: openAppStore))
    #endif

    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
      self.tableView.deselectRow(at: indexPath, animated: true)
    }))

    present(alertController, animated: true, completion: nil)
  }

  override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
    return 90.0
  }
}

extension AppStoreSearchResultTableViewController: UISearchResultsUpdating {
  /**
   Update the current table view based on the search term.
   */
  func updateSearchResults(for searchController: UISearchController) {
    self.dataTask?.cancel()

    // get the search term
    guard let term = searchController.searchBar.text else {
      result = .success([AppleSearchResultItem]())
      return
    }

    // if the search term is empty, do nothing
    guard !term.isEmpty else {
      return
    }

    result = nil

    // create the url for the query
    var urlComponents = AppStoreSearchResultTableViewController.baseURLComponents

    urlComponents.queryItems?.append(URLQueryItem(name: "term", value: term))

    let url = urlComponents.url!

    // create the data task for the url
    let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in

      // update the results
      self.result = AppsTableViewController.jsonDecoder.decode(AppleSearchResult.self,
                                                               from: data,
                                                               withResponse: response,
                                                               withError: error,
                                                               elseError: NoDataError()).map { $0.results }
      self.dataTask = nil
    }

    DispatchQueue.global().async {
      dataTask.resume()
    }
    self.dataTask = dataTask
  }
}

extension AppStoreSearchResultTableViewController: TabItemable {
  func configureTabItem(_ tabItem: UITabBarItem) {
    tabItem.title = "Search"
    tabItem.image = UIImage(systemName: "magnifyingglass")
  }
}

#if !targetEnvironment(simulator)
  // StoreKit disabled on simulator since there's no App Store
  extension AppStoreSearchResultTableViewController: SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
      viewController.dismiss(animated: true) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
          self.tableView.deselectRow(at: indexPath, animated: true)
        }
      }
    }
  }
#endif
