//
//  LoginViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/16/19.
//
import UIKit

class LoginViewController: UIViewController {
  
  @IBOutlet weak var urlTextField: UITextField!
  @IBOutlet weak var usernameTextField : UITextField!
  
  var urlComponents : URLComponents? {
    guard let text = urlTextField.text else {
      return nil
    }
    return URLComponents(string: text)
  }
  @IBOutlet var buttons: [UIButton]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  @IBAction func signupWithButton(_ sender: UIButton, forEvent event: UIEvent) {
    guard var urlComponents = self.urlComponents else {
      return
    }
    
    urlComponents.path = "users"
    
    guard let url = urlComponents.url else {
      return
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    
    URLSession.shared.dataTask(with: urlRequest) { (_, _, error) in
      if let error = error {
        return
      }
      DispatchQueue.main.async {
        let tabViewController = UITabBarController()
        tabViewController.setViewControllers([AppStoreSearchResultTableViewController()], animated: false)
        self.navigationController?.pushViewController(tabViewController, animated: true)
      }
    }
  }
  
  @IBAction func loginWithButton(_ sender: UIButton, forEvent event: UIEvent) {
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