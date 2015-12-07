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
    public let body: [UInt8]

    init(bytes: [CChar]) {
        let parsed = HTTPRequestParser(raw: bytes)
        self.method = parsed.method
        self.path = parsed.path
        self.proto = parsed.proto
        self.headers = parsed.headers
        self.body = parsed.body
    }

}

class HTTPRequestParser {

    static let LF = CChar(10)
    static let CR = CChar(13)

    enum Mode {
        case First
        case Header
        case Empty
        case Body
    }

    var method: String
    var path: String
    var proto: String
    var headers: [String: String]
    var body: [UInt8]

    class State {
        var mode = Mode.First
        var buffer = [CChar]()

        var method: String!
        var path: String!
        var proto: String!
        var headers = [String: String]()
    }

    init(raw: [CChar]) {
        let parsed = raw.reduce(State()) { (state, c) in
            if c == HTTPRequestParser.LF && state.mode != .Body {
                var leftChars = [CChar](state.buffer)
                leftChars.removeLast()
                leftChars.append(0)
                let line = String.fromCString(leftChars) ?? ""
                if state.mode == .First {
                    let fields = line.characters.split(" ", maxSplit: 3, allowEmptySlices: true)
                    state.method = String(fields[0])
                    state.path = String(fields[1])
                    state.proto = String(fields[2])
                    state.mode = .Header
                }
                else if state.mode == .Header {
                    if line.isEmpty || line == String(HTTPRequestParser.CR) {
                        state.mode = .Empty
                    }
                    else {
                        let field = line.characters.split(":", maxSplit: 2, allowEmptySlices: true)
                        let name = String(field[0])
                        let value = String(field[1]).trimLeft(" ", maxCount: 1)
                        state.headers[name] = value
                    }
                }
                else if state.mode == .Empty {
                    state.mode = .Body
                }
                state.buffer.removeAll()
                return state
            }
            state.buffer.append(c)
            return state
        }
        method = parsed.method
        path = parsed.path
        proto = parsed.proto
        headers = parsed.headers
        body = parsed.buffer.map { c in
            return UInt8(c)
        }
    }

}
