//
//  AppsTableViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/24/19.
//

import UIKit

// StoreKit disabled on simulator since there's no App Store
#if !targetEnvironment(simulator)
  import StoreKit
#endif

/**
 UITableViewController for displaying the set of apps saved by the user.
 */
class AppsTableViewController: UITableViewController {
  /**
   Reuse Identifier for each UITableViewCell.
   */
  static let reuseIdentifier = "reuseIdentifier"

  /**
   JSON Decoder for data from api.
   */
  static let jsonDecoder = JSONDecoder()

  /**
   Active Data Task.
   */
  var dataTask: URLSessionDataTask?

  /**
   Observer for watching changes to the user app collection.
   */
  var observer: NSObjectProtocol?

  /**
   Access to the activity indicator and overlay.
   */
  weak var busyView: UIView!

  /**
   Current error UIAlertController
   */
  weak var alertController: UIAlertController?

  /**
   Decoded result from api call or error.
   */
  var result: Result<[ProductResponse], Error>? {
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

    // observe changes to the user's app collection
    observer = NotificationCenter.default.addObserver(
      forName: NotificationNames.AppCollectionUpdated,
      object: nil, queue: nil, using: onUpdate(notification:)
    )

    let cellNib = UINib(nibName: "AppStoreSearchResultTableViewCell", bundle: nil)
    // register the UITableViewCell
    tableView.register(cellNib, forCellReuseIdentifier: AppsTableViewController.reuseIdentifier)
  }

  /**
   Update the current table view.
   */
  func beginUpdate() {
    // build the request for listing the products
    guard let request = try? RequestBuilder.shared.request(withPath: "/products", andMethod: "GET") else {
      return
    }

    // start the call to the API
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      // decode the result
      self.result = AppsTableViewController.jsonDecoder.decode([ProductResponse].self,
                                                               from: data,
                                                               withResponse: response,
                                                               withError: error,
                                                               elseError: NoDataError())
      self.dataTask = nil
    }
    dataTask = task
    task.resume()
  }

  /**
   When the notification is received then update the list.
   */
  func onUpdate(notification _: Notification) {
    beginUpdate()
  }

  /**
   Update the list the first time the view appears.
   */
  override func viewDidAppear(_: Bool) {
    guard dataTask == nil, result == nil else {
      return
    }
    beginUpdate()
  }

  // MARK: - Table view data source

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return result.flatMap { try? $0.get() }?.count ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // dequeue the UITableViewCell
    let cell = tableView.dequeueReusableCell(withIdentifier: AppsTableViewController.reuseIdentifier, for: indexPath)

    // try to cast as AppStoreSearchResultTableViewCell
    guard let productCell = cell as? AppStoreSearchResultTableViewCell else {
      return cell
    }

    // try to get the product based on the indexPath
    guard let product = (try? self.result?.get())?[indexPath.row] else {
      return productCell
    }

    // if the product has an image, load the image into the view
    if let sourceImageUrl = product.sourceImageUrl {
      DispatchQueue.global().async {
        guard let data = try? Data(contentsOf: sourceImageUrl) else {
          return
        }
        DispatchQueue.main.async {
          productCell.artworkView.image = UIImage(data: data)
        }
      }
    }

    productCell.nameLabel.text = product.name
    productCell.subtitleLabel.text = "by \(product.developer.name)"

    return productCell
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

      guard let product = (try? result?.get())?[indexPath.row] else {
        return
      }

      guard let trackId = product.appleSoftware?.trackId else {
        return
      }

      let storeController = SKStoreProductViewController()
      storeController.delegate = self

      // load the product into the the Store Product View
      storeController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: trackId]) { loaded, _ in
        // if loaded present the Store Product View
        if loaded {
          self.present(storeController, animated: true, completion: nil)
        }
      }
    }
  #endif

  /**
   Removes  the currently selected product from the user's app list.
   */
  func removeAction(_: UIAlertAction) {
    // get the indexPath
    guard let indexPath = self.tableView.indexPathForSelectedRow else {
      return
    }

    guard let product = (try? result?.get())?[indexPath.row] else {
      return
    }
    guard let request =
      try? RequestBuilder.shared.request(withPath: "/products/\(product.id)", andMethod: "DELETE") else {
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

  /**
   Displays an action sheet when the user selects a product.
   */
  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let product = (try? result?.get())?[indexPath.row] else {
      return
    }

    let alertController = UIAlertController(title: product.name, message: "What would you like to do?", preferredStyle: .actionSheet)

    alertController.addAction(UIAlertAction(title: "Remove App", style: .destructive, handler: removeAction))

    // If the app has a web site, allow the user to open the web site url.

    if let url = product.url {
      alertController.addAction(UIAlertAction(title: "Open Website", style: .default, handler: { _ in
        UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey: Any](), completionHandler: { _ in
          self.tableView.deselectRow(at: indexPath, animated: true)
        })
      }))
    }
    // StoreKit disabled on simulator since there's no App Store
    #if !targetEnvironment(simulator)

      // if the product has an app store page, allow the user to show the product page
      if product.appleSoftware?.trackId != nil {
        alertController.addAction(UIAlertAction(title: "Open App Store", style: .default, handler: openAppStore))
      }
    #endif

    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
      self.tableView.deselectRow(at: indexPath, animated: true)
    }))

    present(alertController, animated: true, completion: nil)
  }

  override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
    return 120.0
  }

  deinit {
    // remove the observer when the view is deinitialized
    if let observer = self.observer {
      NotificationCenter.default.removeObserver(observer)
    }
    observer = nil
  }
}

extension AppsTableViewController: TabItemable {
  func configureTabItem(_: UITabBarItem) {
    tabBarItem.title = "Apps"
    tabBarItem.image = UIImage(systemName: "app.badge.fill")
  }
}

// StoreKit disabled on simulator since there's no App Store
#if !targetEnvironment(simulator)
  extension AppsTableViewController: SKStoreProductViewControllerDelegate {
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
      viewController.dismiss(animated: true) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
          self.tableView.deselectRow(at: indexPath, animated: true)
        }
      }
    }
  }
#endif
