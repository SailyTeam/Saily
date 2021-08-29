@testable import AptRepository
@testable import Dog
import XCTest

final class AptTests: XCTestCase {
    func testExample() {
        try? Dog.shared.initialization()

        _ = PackageCenter.default

//        let url = URL(string: "http://10.60.1.235/localtestrepo")!
//        center.registerRepository(withUrl: url)
//
//        DispatchQueue.global().async {
//            while true {
//                center.dispatchUpdateOnRepository(withUrl: url)
//            }
//        }
    }
}
