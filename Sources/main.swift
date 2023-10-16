// convert axera annotation format to coco format

// import necessary packages for json
import Foundation

// define the path to input json files
let jsonsURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/ANNOTATION_roadmark/FRONT_rect/")
let imageURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/IMAGE/FRONT_rect")
// define the path to output json files
let cocoURL = URL(fileURLWithPath: "/coco/gaoyi_dataset/coco/aXcellent_roadmark_FRONT_rect/annotations/all.json")

// create the output coco directory and file
do {
    try FileManager.default.createDirectory(at: cocoURL, withIntermediateDirectories: true, attributes: nil)
} catch {
    print(error)
}

// iter through jsonsURL to read json files
let jsons = try FileManager.default.contentsOfDirectory(at: jsonsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
let sortedJSONs = jsons.sorted { (url1, url2) -> Bool in
    return url1.lastPathComponent < url2.lastPathComponent
}
for (index, json) in sortedJSONs.enumerated() {
    let coco_json = try! String(contentsOf: json)
    print(coco_json)
    if (index == 1) {
        break
    }
}
