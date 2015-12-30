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

    let socket: Socket

    init(socket: Socket) {
        self.socket = socket
    }

    func read() throws -> Int8? {
        return try read(1).first
    }

    func read(maxLength: Int) throws -> [Int8] {
        let buffer = UnsafeMutablePointer<Int8>.alloc(maxLength)
        memset(buffer, 0, maxLength)
        let size = recv(socket.raw, buffer, maxLength, 0)
        if size < 0 {
            throw ReaderError.GenericError(error: errno)
        }
        var bytes = [Int8]()
        for i in 0..<size {
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

    var reading = true

    func flush() -> [Int8]? {
        let size = buffer.count
        for i in 0..<size {
            if buffer[i] == LF {
                let line = [Int8](buffer[0...i])
                if i + 1 >= size {
                    buffer = []
                }
                else {
                    buffer = [Int8](buffer[(i + 1)..<size])
                }
                return line
            }
        }
        return nil
    }

    func read() throws -> [Int8]? {
        if let line = flush() {
            return line
        }
        let batch = 128
        while reading {
            let chunk = try reader.read(batch)
            if chunk.count == 0 {
                reading = false
            }
            else if chunk.count < batch {
                reading = false
            }
            buffer.appendContentsOf(chunk)
            if let line = flush() {
                return line
            }
        }
        if buffer.count > 0 {
            let line = buffer
            buffer.removeAll()
            return line
        }
        return nil
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
