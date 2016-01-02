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

public struct Socket {

    static let defaultDomain: Int32 = AF_INET
#if os(OSX)
    static let defaultType: Int32 = SOCK_STREAM
#else
    static let defaultType: Int32 = Int32(SOCK_STREAM.rawValue)
#endif

    var underlying: Int32

    public init?(domain: Int32 = defaultDomain, type: Int32 = defaultType, proto: Int32 = 0) {
        underlying = socket(domain, Int32(type), proto)
        if underlying <= 0 {
            return nil
        }
    }

    public func bindAddress(address: UnsafeMutablePointer<Void>, length: socklen_t) -> Bool {
        return bind(underlying, UnsafeMutablePointer<sockaddr>(address), length) == 0
    }

    public func setOption(option: Int32, value: Int32) {
        var val = value
        setsockopt(underlying, SOL_SOCKET, option, &val, socklen_t(sizeof(Int32)))
    }
}

public struct SocketAddress {

    static let defaultDomain = AF_INET

    var underlying: sockaddr_in

    static func htons(value: CUnsignedShort) -> CUnsignedShort {
        return value.bigEndian
    }

    public init(port: UInt16, domain: Int32 = defaultDomain) {
#if os(OSX)
        underlying = sockaddr_in(
            sin_len: __uint8_t(sizeof(sockaddr_in)),
            sin_family: sa_family_t(AF_INET),
            sin_port: SocketAddress.htons(port),
            sin_addr: in_addr(s_addr: in_addr_t(0)),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )
#else
        underlying = sockaddr_in(
            sin_family: sa_family_t(AF_INET),
            sin_port: SocketAddress.htons(port),
            sin_addr: in_addr(s_addr: in_addr_t(0)),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )
#endif
    }

}
