import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  // Basic "It works" example
  router.get { req in
    return "It works!"
  }
  
  // Basic "Hello, world!" example
  router.get("hello") { req in
    return "Hello, world!"
  }
  
  let userController = UserController()
  router.post("users", use: userController.create)
  //router.get("users", use: userController.get)
  // Example of configuring a controller
  
  //    let todoController = ProductController()
  //    router.get("todos", use: todoController.index)
  //    router.post("todos", use: todoController.create)
  //    router.delete("todos", App.parameter, use: todoController.delete)
}
