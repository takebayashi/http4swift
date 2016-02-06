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

@testable import http4swift

class HTTPRequestTests: TestCase {

    func runAll() {
        testParser()
    }

    func testParser() {
        let CRLF = "\r\n"
        let r =
            "POST /foo/bar HTTP/1.0" + CRLF +
            CRLF +
            "post_body"
        let reader = BufferReader(buffer: r.bytes())
        let parsed = try! HTTPRequest.Parser.parse(reader)

        assert(parsed.method == "POST", "pasing HTTP request method")
        assert(parsed.path == "/foo/bar", "pasing HTTP request path")
        assert(parsed.body == "post_body", "parsing HTTP request body")
        assert(parsed.bodyBytes == "post_body".bytes(), "parsing HTTP request body")
    }

}
