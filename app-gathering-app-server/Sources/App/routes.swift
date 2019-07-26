import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  let productController = ProductController()
  let platformController = PlatformController()
  let userController = UserController()
  let apswProductController = AppleSoftwareProductController(platformController: platformController)

  // "login"
  router.post("users", use: userController.create)

  // "signup"
  router.get("users", String.parameter, use: userController.get)

  // import and add the user's list of apps
  router.post("iTunesProducts", Int.parameter, use: apswProductController.create)

  // get the user's list of products
  router.get("products", use: productController.list)

  // remove the product from user's list
  router.delete("products", UUID.parameter, use: productController.delete)
}
