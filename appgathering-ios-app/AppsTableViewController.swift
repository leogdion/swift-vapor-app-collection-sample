//
//  AppsTableViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/24/19.
//

import UIKit

extension JSONDecoder {
  func decode<T>(_ type: T.Type, from data: Data?, withError error: Error?, elseError defaultError: Error) -> Result<T, Error> where T: Decodable {
    let result: Result<T, Error>
    if let error = error {
      result = .failure(error)
    } else if let data = data {
      do {
        let products = try decode(type, from: data)

        result = .success(products)
      } catch {
        result = .failure(error)
      }
    } else {
      result = .failure(defaultError)
    }
    return result
  }
}

class AppsTableViewController: UITableViewController, TabItemable {
  var loaded = false
  let jsonDecoder = JSONDecoder()
  var observer: NSObjectProtocol?

  weak var busyView: UIView!
  let reuseIdentifier = "reuseIdentifier"
  var result: Result<[ProductResponse], Error>? {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = false

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

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // navigationItem.rightBarButtonItem = editButtonItem
    observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "AppCollectionUpdated"), object: nil, queue: nil, using: onUpdate(notification:))

    tableView.register(UINib(nibName: "AppStoreSearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
  }

  func begin() {
    guard let request = try? RequestBuilder.shared.request(withPath: "/products", andMethod: "GET") else {
      return
    }

    URLSession.shared.dataTask(with: request) { data, _, error in
      self.result = self.jsonDecoder.decode([ProductResponse].self, from: data, withError: error, elseError: NoDataError())
      DispatchQueue.main.async {
        self.busyView.isHidden = true
      }

    }.resume()
  }

  @objc
  func onUpdate(notification _: Notification) {
    begin()
  }

  override func viewDidAppear(_: Bool) {
    guard !loaded else {
      return
    }
    begin()
    loaded = true
  }

  // MARK: - Table view data source

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return result.flatMap { try? $0.get() }?.count ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

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

      // NotificationCenter.default.post(name: NSNotification.Name(rawValue: "AppCollectionUpdated"), object: nil)
    }.resume()
  }

  override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let product = (try? result?.get())?[indexPath.row] else {
      return
    }

    let alertController = UIAlertController(title: product.name, message: "What would you like to do?", preferredStyle: .actionSheet)

    alertController.addAction(UIAlertAction(title: "Remove App", style: .destructive, handler: removeAction))

    if let url = product.url {
      alertController.addAction(UIAlertAction(title: "Open Website", style: .default, handler: {
        _ in
        UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey: Any](), completionHandler: {
          _ in
          self.tableView.deselectRow(at: indexPath, animated: true)
        })
      }))
    }

    #if !targetEnvironment(simulator)
      if product.appleSoftware?.trackId != nil {
        alertController.addAction(UIAlertAction(title: "Open App Store", style: .default, handler: openAppStore))
      }
    #endif

    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
      _ in
      self.tableView.deselectRow(at: indexPath, animated: true)
    }))

    present(alertController, animated: true, completion: nil)
  }

  override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
    return 120.0
  }

  func configureTabItem(_: UITabBarItem) {
    tabBarItem.title = "Apps"
    tabBarItem.image = UIImage(systemName: "app.badge.fill")
  }

  override func viewWillDisappear(_ animated: Bool) {
    if let observer = self.observer {
      NotificationCenter.default.removeObserver(observer)
    }
    observer = nil
    super.viewWillDisappear(animated)
  }
}
