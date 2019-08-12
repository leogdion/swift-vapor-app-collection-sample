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

//
//  LoginViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/16/19.
//
import UIKit

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

    guard let urlRequest = try? RequestBuilder.shared.request(usingBaseUrl: baseUrl, withPath: "/users", andMethod: "POST", andBody: SignupRequest(name: userName)) else {
      return
    }
    let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

      let result = self.jsonDecoder.decode(UserResponse.self, from: data, withResponse: response, withError: error, elseError: NoDataError())

      guard let userResponse = try? result.get() else {
        return
      }

      RequestBuilder.shared.save(baseUrl: baseUrl, forUserWithId: userResponse.id)

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
    guard let urlRequest = try? RequestBuilder.shared.request(usingBaseUrl: baseUrl, withPath: "/users/\(userName)", andMethod: "GET") else {
      return
    }
    let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
      let result = self.jsonDecoder.decode(UserResponse.self, from: data, withResponse: response, withError: error, elseError: NoDataError())

      guard let userResponse = try? result.get() else {
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
