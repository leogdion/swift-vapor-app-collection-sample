import Vapor

/// Controls basic CRUD operations on `Todo`s.
final class ProductController {
    /// Returns a list of all `Todo`s.
    func index(_ req: Request) throws -> Future<[Product]> {
        return Product.query(on: req).all()
    }

    /// Saves a decoded `Todo` to the database.
    func create(_ req: Request) throws -> Future<Product> {
        return try req.content.decode(Product.self).flatMap { todo in
            return todo.save(on: req)
        }
    }

    /// Deletes a parameterized `Todo`.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Product.self).flatMap { todo in
            return todo.delete(on: req)
        }.transform(to: .ok)
    }
}
