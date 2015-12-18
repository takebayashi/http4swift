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

#if os(OSX)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

enum ReaderError: ErrorType {
    case GenericError(error: Int32)
}

protocol Reader {

    typealias Entry

    func read() throws -> Entry?

    func read(maxLength: Int) throws -> [Entry]

}

class SocketReader: Reader {

    typealias Entry = Int8

    let socket: Int32

    init(socket: Int32) {
        self.socket = socket
    }

    func read() throws -> Int8? {
        return try read(1).first
    }

    func read(maxLength: Int) throws -> [Int8] {
        let buffer = UnsafeMutablePointer<Int8>.alloc(maxLength)
        memset(buffer, 0, maxLength)
        let size = recv(socket, buffer, maxLength, 0)
        if size < 0 {
            throw ReaderError.GenericError(error: errno)
        }
        var bytes = [Int8]()
        for i in 0..<maxLength {
            bytes.append(buffer[i])
        }
        buffer.dealloc(maxLength)
        return bytes
    }

}

let LF = Int8(10)

class BufferedReader<R: Reader where R.Entry == Int8>: Reader {

    typealias Entry = [Int8]

    let reader: R

    init(reader: R) {
        self.reader = reader
    }

    var buffer = [Int8]()

    func flush() -> [Int8]? {
        for i in 0..<buffer.count {
            if buffer[i] == LF {
                return [Int8](buffer.dropFirst(i + 1))
            }
        }
        return nil
    }

    func read() throws -> [Int8]? {
        if let line = flush() {
            return line
        }
        while true {
            let chunk = try reader.read(128)
            if chunk.count == 0 {
                if buffer.count == 0 {
                    return nil
                }
                return buffer
            }
            buffer.appendContentsOf(chunk)
            if let line = flush() {
                return line
            }
        }
    }

    func read(maxLength: Int) throws -> [[Int8]] {
        var lines = [[Int8]]()
        for _ in 0..<maxLength {
            if let line = try read() {
                lines.append(line)
            }
            else {
                break
            }
        }
        return lines
    }

}
