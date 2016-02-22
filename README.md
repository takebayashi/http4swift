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

let addr = SocketAddress(port: 8080)
guard let sock = Socket() else {
    return
}
guard let server = HTTPServer(socket: sock, addr: addr) else {
    return
}

server.serve(app)
```
