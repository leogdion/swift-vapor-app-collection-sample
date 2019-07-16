//
//  LoginViewController.swift
//  appgathering-ios-app
//
//  Created by Leo Dion on 7/16/19.
//
import UIKit

class LoginViewController: UIViewController {
  
  @IBOutlet weak var usernameTextField : UITextField!
  @IBOutlet var buttons: [UIButton]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
  
  @IBAction func signupWithButton(_ sender: UIButton, forEvent event: UIEvent) {
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
