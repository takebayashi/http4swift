# http4swift

http4swift is a tiny HTTP server library for [Nest](https://github.com/nestproject/Nest)-compatible applications.

This project is unstable, and the API might be changed at anytime before we reach a stable version.

## Usage

```
import http4swift
import Nest

let app: Application = { (request) -> ResponseType in
    // ...
}

guard let server = HTTPServer(port: 8080) else {
    fatalError()
}

server.serve(app)
```

## Versions

- v0.3.x
  * Nest 0.3 compatibility
- v0.2.x
  * Nest 0.2 compatibility
- v0.1.x
  * First release
