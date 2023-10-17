import Foundation
@testable import swift_coco
import XCTest

final class MyTest: XCTestCase {
    func testDecodeOneJson() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(MyLibrary().text, "Hello, World!")
        let jsonURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/ANNOTATION_roadmark/FRONT_rect/1692588188.700129986.json")
        let jsonString = try String(contentsOf: jsonURL, encoding: .utf8)

        if let jsonData = jsonString.data(using: .utf8) {
            let decoder = JSONDecoder()
            let axera_img_anno = try decoder.decode(AxeraImageAnno.self, from: jsonData)
            XCTAssertEqual(axera_img_anno.auditId, "a0d895ab-c07d-411a-8038-60036cfdf887.567.audit")
            XCTAssertEqual(axera_img_anno.instances[0].categoryName, "路面箭头")
            XCTAssertEqual(axera_img_anno.instances[0].attributes?["occlusion"], "0")
            XCTAssertEqual(axera_img_anno.instances[0].attributes?["type"], "unknown")
            XCTAssertEqual(axera_img_anno.instances[0].children[0].id, "1c974fb8-5a90-4708-a8ff-54ac5fb25e74")
            // print(axera_img_anno.instances[0].children[0].cameras[0].frames[0].shape)
            switch axera_img_anno.instances[0].children[0].cameras[0].frames[0].shape {
                case .rectangle(let rectangle):
                    print(rectangle.x)
                default:
                    break
            }
        }
    }
}

// do {
// } catch {
//     print("Error: \(error.localizedDescription)")
// }
