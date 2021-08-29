@testable import Dog
import XCTest

final class DogTests: XCTestCase {
    func testExample() {
        do {
            try Dog.shared.initialization()
        } catch {
            XCTFail(error.localizedDescription)
        }
        Dog.shared.join(self, "Hello World!", level: .info)
    }
}
