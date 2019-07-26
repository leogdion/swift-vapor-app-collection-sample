import FluentPostgreSQL
import Vapor

public struct PostgresDefaults {
  public static let hostname = "localhost"
  public static let username = "app_gathering"
  public static let port = 5432
}

/// Called before your application initializes.
public func configure(_: inout Config, _: inout Environment, _ services: inout Services) throws {
  // Register providers first
  try services.register(FluentPostgreSQLProvider())

  // Register routes to the router
  let router = EngineRouter.default()
  try routes(router)
  services.register(router, as: Router.self)

  // Register middleware
  var middlewares = MiddlewareConfig() // Create _empty_ middleware config
  // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
  middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
  services.register(middlewares)

  // Configure a SQLite database
  let postgreSQLConfig: PostgreSQLDatabaseConfig

  if let url = Environment.get("DATABASE_URL") {
    postgreSQLConfig = PostgreSQLDatabaseConfig(url: url)!
  } else {
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? PostgresDefaults.hostname
    let username = Environment.get("DATABASE_USERNAME") ?? PostgresDefaults.username
    let database = Environment.get("DATABASE_DATABASE")
    let password = Environment.get("DATABASE_PASSWORD")

    let port: Int

    if let portString = Environment.get("DATABASE_PORT") {
      port = Int(portString) ?? PostgresDefaults.port
    } else {
      port = PostgresDefaults.port
    }

    postgreSQLConfig = PostgreSQLDatabaseConfig(
      hostname: hostname,
      port: port,
      username: username,
      database: database,
      password: password,
      transport: .cleartext
    )
  }
  let postgreSQL = PostgreSQLDatabase(config: postgreSQLConfig)

  // Register the configured SQLite database to the database config.
  var databases = DatabasesConfig()
  databases.add(database: postgreSQL, as: .psql)
  services.register(databases)

  // Configure migrations
  var migrations = MigrationConfig()
  migrations.add(model: User.self, database: .psql)
  migrations.add(model: Developer.self, database: .psql)
  migrations.add(model: Product.self, database: .psql)
  migrations.add(model: Platform.self, database: .psql)
  migrations.add(model: ProductPlatform.self, database: .psql)
  migrations.add(model: UserProduct.self, database: .psql)
  migrations.add(model: AppleSoftwareDeveloper.self, database: .psql)
  migrations.add(model: AppleSoftwareProduct.self, database: .psql)
  services.register(migrations)
}
