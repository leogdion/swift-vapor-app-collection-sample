// Copyright (c) 2019 Razeware LLC
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the  Software), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical or
// instructional purposes related to programming, coding, application development,
// or information technology.  Permission for such use, copying, modification,
// merger, publication, distribution, sublicensing, creation of derivative works,
// or sale is expressly withheld.
// THE SOFTWARE IS PROVIDED  AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

extension JSONDecoder {
  /**
   Decode the result of a  data task into a Decodable object.

    - Parameter type: Target Decoding Type
    - Parameter data: The optional data from the data task to decode.
    - Parameter error: The optional error from the data task.
    - Parameter defaultError: The error to return if there is no data or error.
   */
  func decode<T>(_ type: T.Type, from data: Data?, withResponse response: URLResponse?, withError error: Error?, elseError defaultError: Error) -> Result<T, Error> where T: Decodable {
    let result: Result<T, Error>
    if let error = error {
      result = .failure(error)
    } else if response?.isNotImplemented == true {
      result = .failure(NotImplmentedError())
    } else if let data = data {
      do {
        let products = try decode(type, from: data)

        result = .success(products)
      } catch {
        result = .failure(error)
      }
    } else {
      result = .failure(defaultError)
    }
    return result
  }
}
