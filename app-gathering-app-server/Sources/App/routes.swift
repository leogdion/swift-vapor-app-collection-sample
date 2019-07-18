import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  // Basic "It works" example
  router.get { _ in
    "It works!"
  }

  // Basic "Hello, world!" example
  router.get("hello") { _ in
    "Hello, world!"
  }

  let userController = UserController()
  router.post("users", use: userController.create)

  router.get("users", String.parameter, use: userController.get)
  // Example of configuring a controller

  let apswProductController = AppleSoftwareProductController()
  router.post("iTunesProducts", Int.parameter, use: apswProductController.create)
  //    let todoController = ProductController()
  //    router.get("todos", use: todoController.index)
  //    router.post("todos", use: todoController.create)
  //    router.delete("todos", App.parameter, use: todoController.delete)
}
