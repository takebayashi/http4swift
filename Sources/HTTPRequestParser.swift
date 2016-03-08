/*
 The MIT License (MIT)

 Copyright (c) 2015 Shun Takebayashi

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

import Nest
import NestUtil
import SwallowIO

enum HTTPRequestParserError: ErrorType {
    case InvalidRequest(details: String)
}

protocol HTTPRequestParser {

    func parse() throws -> HTTPRequest

}

class DefaultHTTPRequestParser<R: Reader where R.Entry == Byte>: HTTPRequestParser {

    var reader: R

    init(reader: R) {
        self.reader = reader
    }

    func parse() throws -> HTTPRequest {
        let requestLine = try getLineString()
        let (method, path, version) = try parseRequestLine(requestLine)
        var headers = [Header]()

        while true {
            let headerLine = try getLineString()
            if headerLine == "" {
                break
            }
            headers.append(try parseHeaderLine(headerLine))
        }

        let contentLength = Int(headers["Content-Length"] ?? "0") ?? 0
        var body = [Byte]()
        if contentLength > 0 {
            body = try reader.read(contentLength)
        }
        else if headers["Transfer-Encoding"] == "chunked" {
            while true {
                let lengthHex = try getLineString()
                let chunkLength = Int(lengthHex, radix: 16) ?? 0
                if chunkLength == 0 {
                    break
                }
                body.appendContentsOf(try reader.read(chunkLength))
            }
        }

        return HTTPRequest(method: method, path: path, version: version, headers: headers, body: body.map({ Int8($0) }))
    }

    func parseRequestLine(line: String) throws -> (String, String, String) {
          let fields = line.characters.split(" ", maxSplit: 2, allowEmptySlices: true)
          if fields.count != 3 {
              throw HTTPRequestParserError.InvalidRequest(details: "Invalid request line")
          }
          let method = String(fields[0])
          let path = String(fields[1])
          let version = String(fields[2])
          return (method, path, version)
    }

    func parseHeaderLine(line: String) throws -> (String, String) {
        let field = line.characters.split(":", maxSplit: 1, allowEmptySlices: true)
        if field.count != 2 {
          print("error VV")
            print(line)
              print("error AA")
            throw HTTPRequestParserError.InvalidRequest(details: "Invalid header")
        }
        let name = String(field[0])
        let value = String(field[1]).trimLeft(" ", maxCount: 1)
        return (name, value)
    }

    func getLineString() throws -> String {
        let CRLF: [Byte] = [13, 10]
        var buffer = try reader.read(until: CRLF)
        while let last = buffer.last {
            if last == Byte(10) || last == Byte(13) {
                buffer.removeLast()
            }
            else {
                break
            }
        }
        buffer.append(Byte(0))
        return try buffer.map({ Int8($0) }).withUnsafeBufferPointer { bytes in
            guard let string = String.fromCString(bytes.baseAddress) else {
                throw HTTPRequestParserError.InvalidRequest(details: "Invalid request")
            }
            return string
        }
    }

}
