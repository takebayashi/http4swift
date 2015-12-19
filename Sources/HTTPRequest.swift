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

public struct HTTPRequest {

    public let method: String
    public let path: String
    public let proto: String
    public let headers: [String: String]
    public let body: [Int8]

    init(method: String, path: String, version: String, headers: [String: String], body: [Int8]) {
        self.method = method
        self.path = path
        self.proto = version
        self.headers = headers
        self.body = body
    }


    class Parser {

        static let CRLF = Character("\r\n")

        enum Mode {
            case First
            case Header
            case Empty
            case Body
        }

        static func parse<R: Reader where R.Entry == Int8>(reader: R) -> HTTPRequest {
            let bufferedReader = BufferedReader(reader: reader)
            var mode = Mode.First

            var method: String!
            var path: String!
            var version: String!
            var headers = [String: String]()
            var body = [Int8]()

            while let line = try! bufferedReader.read() {
                var bytes = line
                bytes.append(0)
                let str = (String.fromCString(bytes) ?? "").trimRight(CRLF)
                switch mode {
                case .First:
                    let fields = str.characters.split(" ", maxSplit: 3, allowEmptySlices: true)
                    method = String(fields[0])
                    path = String(fields[1])
                    version = String(fields[2])
                    mode = .Header
                case .Header:
                    if str.isEmpty {
                        mode = .Empty
                    }
                    else {
                        let field = str.characters.split(":", maxSplit: 2, allowEmptySlices: true)
                        let name = String(field[0])
                        let value = String(field[1]).trimLeft(" ", maxCount: 1)
                        headers[name] = value
                    }
                case .Empty:
                    mode = .Body
                    fallthrough
                case .Body:
                    body.appendContentsOf(line)
                }
            }

            return HTTPRequest(method: method, path: path, version: version, headers: headers, body: body)
        }

    }

}

