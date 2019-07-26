//
//  LoginViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/16/19.
//
import UIKit

struct SignupRequest: Codable {
  let name: String
}

struct UserResponse: Codable {
  let name: String
  let id: UUID
}

class LoginViewController: UIViewController {
  @IBOutlet var urlTextField: UITextField!
  @IBOutlet var usernameTextField: UITextField!
  let jsonDecoder = JSONDecoder()

  var urlComponents: URLComponents? {
    guard let text = urlTextField.text else {
      return nil
    }
    return URLComponents(string: text)
  }

  @IBOutlet var buttons: [UIButton]!

  override func viewDidLoad() {
    super.viewDidLoad()

    if let serverUrl = ProcessInfo.processInfo.environment["DEFAULT_SERVER"]
      .flatMap(URL.init(string:)) ?? UserDefaults.standard.url(forKey: "baseUrl") {
      urlTextField.text = serverUrl.absoluteString
    }

    // Do any additional setup after loading the view.
    guard let idString = UserDefaults.standard.string(forKey: "userId") else {
      return
    }

    guard UUID(uuidString: idString) != nil else {
      return
    }

    loginWith(idString)
  }

  @IBAction func signupWithButton(_: UIButton, forEvent _: UIEvent) {
    guard let baseUrlComponents = self.urlComponents else {
      return
    }

    guard let userName = self.usernameTextField.text else {
      return
    }

    guard let baseUrl = baseUrlComponents.url else {
      return
    }

    var urlComponents = baseUrlComponents

    urlComponents.path = "/users"

    guard let url = urlComponents.url else {
      return
    }

    let jsonEncoder = JSONEncoder()

    guard let body = try? jsonEncoder.encode(SignupRequest(name: userName)) else {
      return
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = body
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let task = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
      if error != nil {
        return
      }
      guard let data = data else {
        return
      }
      guard let userResponse = try? self.jsonDecoder.decode(UserResponse.self, from: data) else {
        return
      }
      RequestBuilder.shared.save(baseUrl: baseUrl, forUserWithId: userResponse.id)
//      UserDefaults.standard.set(userResponse.id.uuidString, forKey: "userId")
//      UserDefaults.standard.set(self.urlComponents?.url, forKey: "baseUrl")

      DispatchQueue.main.async {
        self.dismiss(animated: true, completion: nil)
      }
    }
    task.resume()
  }

  @IBAction func loginWithButton(_: UIButton, forEvent _: UIEvent) {
    guard let userName = self.usernameTextField.text else {
      return
    }

    loginWith(userName)
  }

  func loginWith(_ userName: String) {
    guard let baseUrlComponents = self.urlComponents else {
      return
    }
    guard let baseUrl = baseUrlComponents.url else {
      return
    }
    var urlComponents = baseUrlComponents
    urlComponents.path = "/users/\(userName)"

    guard let url = urlComponents.url else {
      return
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "GET"
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let task = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
      if error != nil {
        return
      }

      guard let data = data else {
        return
      }
      guard let userResponse = try? self.jsonDecoder.decode(UserResponse.self, from: data) else {
        return
      }
      RequestBuilder.shared.save(baseUrl: baseUrl, forUserWithId: userResponse.id)
      DispatchQueue.main.async {
        self.dismiss(animated: true, completion: nil)
      }
    }
    task.resume()
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
}