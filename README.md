1. Create the Xcode project for the Vapor application.
```
  cd app-gathering-app-server; vapor xcode
```

2. Open workspace file at the root of the folder.

3. On your PostgreSQL instance (server, docker, or vm, etc...), run getting_started.sql, to setup database and user. Currently the app does not require a password for the database user. However if you'd like to supply one, you can use `DATABASE_PASSWORD` as an environment variable and update the sql `GRANT` query accordingly.

4. Run the `Run` target to start the Vapor server application. `appgathering-ios-app` to run the iOS app. You can set the root server url in the login screen or using the environment variable `DEFAULT_SERVER` to ensure the iOS application connects with your Vapor server.
