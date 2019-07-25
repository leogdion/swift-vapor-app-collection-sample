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

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem
    observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "AppCollectionUpdated"), object: nil, queue: nil, using: onUpdate(notification:))

    tableView.register(UINib(nibName: "AppStoreSearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
  }

  func begin() {
    guard let request = try? RequestBuilder.shared.request(withPath: "/products", andMethod: "GET") else {
      return
    }

    URLSession.shared.dataTask(with: request) { data, _, error in
      self.result = self.jsonDecoder.decode([ProductResponse].self, from: data, withError: error, elseError: NoDataError())
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

  /*
   // Override to support conditional editing of the table view.
   override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
       // Return false if you do not want the specified item to be editable.
       return true
   }
   */

  /*
   // Override to support editing the table view.
   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
       if editingStyle == .delete {
           // Delete the row from the data source
           tableView.deleteRows(at: [indexPath], with: .fade)
       } else if editingStyle == .insert {
           // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
       }
   }
   */

  /*
   // Override to support rearranging the table view.
   override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

   }
   */

  /*
   // Override to support conditional rearranging of the table view.
   override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
       // Return false if you do not want the item to be re-orderable.
       return true
   }
   */

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       // Get the new view controller using segue.destination.
       // Pass the selected object to the new view controller.
   }
   */

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
