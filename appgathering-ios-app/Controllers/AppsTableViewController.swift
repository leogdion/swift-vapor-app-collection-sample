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
          self.busyView.isHidden = false
        case let .some(.failure(error)):
          self.alertController?.dismiss(animated: true, completion: nil)
          let alertController = UIAlertController(title: "Error Occured", message: error.localizedDescription, preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
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

  override func viewDidLoad() {
    super.viewDidLoad()

    // add a busy overlay
    busyView = view.addBusyView()

    // observe changes to the user's app collection
    observer = NotificationCenter.default.addObserver(
      forName: NotificationNames.AppCollectionUpdated,
      object: nil, queue: nil, using: onUpdate(notification:)
    )

    // register the UITableViewCell
    tableView.register(UINib(nibName: "AppStoreSearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: AppsTableViewController.reuseIdentifier)
  }

  func begin() {
    guard let request = try? RequestBuilder.shared.request(withPath: "/products", andMethod: "GET") else {
      return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      self.result = AppsTableViewController.jsonDecoder.decode([ProductResponse].self, from: data, withResponse: response, withError: error, elseError: NoDataError())
      DispatchQueue.main.async {
        self.busyView.isHidden = true
      }
      self.dataTask = nil
    }
    dataTask = task
    task.resume()
  }

  func onUpdate(notification _: Notification) {
    begin()
  }

  override func viewDidAppear(_: Bool) {
    guard dataTask == nil, result == nil else {
      return
    }
    begin()
  }

  // MARK: - Table view data source

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return result.flatMap { try? $0.get() }?.count ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: AppsTableViewController.reuseIdentifier, for: indexPath)

    guard let searchResultCell = cell as? AppStoreSearchResultTableViewCell else {
      return cell
    }

    guard let item = (try? self.result?.get())?[indexPath.row] else {
      return searchResultCell
    }

    if let sourceImageUrl = item.sourceImageUrl {
      DispatchQueue.global().async {
        guard let data = try? Data(contentsOf: sourceImageUrl) else {
          return
        }
        DispatchQueue.main.async {
          searchResultCell.artworkView.image = UIImage(data: data)
        }
      }
    }
    // loadArtwork(fromUrl: item.artworkUrl512, forCellAtIndexPath: indexPath)

    searchResultCell.nameLabel.text = item.name
    searchResultCell.subtitleLabel.text = "by \(item.developer.name)"

    return searchResultCell
  }

  // StoreKit disabled on simulator since there's no App Store
  #if !targetEnvironment(simulator)
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
      storeController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: trackId]) { loaded, _ in
        if loaded {
          self.present(storeController, animated: true, completion: nil)
        }
      }
    }
  #endif

  func removeAction(_: UIAlertAction) {
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

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let product = (try? result?.get())?[indexPath.row] else {
      return
    }

    let alertController = UIAlertController(title: product.name, message: "What would you like to do?", preferredStyle: .actionSheet)

    alertController.addAction(UIAlertAction(title: "Remove App", style: .destructive, handler: removeAction))

    if let url = product.url {
      alertController.addAction(UIAlertAction(title: "Open Website", style: .default, handler: { _ in
        UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey: Any](), completionHandler: { _ in
          self.tableView.deselectRow(at: indexPath, animated: true)
        })
      }))
    }
    // StoreKit disabled on simulator since there's no App Store
    #if !targetEnvironment(simulator)
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
