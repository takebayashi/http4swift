import Inquiline
import Nest


public func application(request: RequestType) -> ResponseType {
  switch request.method {
  case "POST":
    if let body = request.body {
      return Response(.Ok, contentType: "text/plain", body: "Hello " + body)
    } else {
      return Response(.NotImplemented, contentType: "text/plain", body: "Request body was empty")
    }
  default:
    return Response(.Ok, contentType: "text/plain", body: "Hello World")
  }
}

if let server = HTTPServer(port: 8080) {
  server.serve(application)
}
