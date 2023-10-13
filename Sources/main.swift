// convert axera annotation format to coco format

// import necessary packages for json
import Foundation

// define the path to input json files
let jsonsURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/ANNOTATION_roadmark/FRONT_rect/")

// define the path to output json files
let cocoURL = URL(fileURLWithPath: "/coco/gaoyi_dataset/coco/aXcellent_roadmark_FRONT_rect/annotations")

// create the output coco directory
do {
    try FileManager.default.createDirectory(at: cocoURL, withIntermediateDirectories: true)
} catch {
    print(error)
}
