// convert axera annotation format to coco format

// import necessary packages for json
import Foundation

// TODO: argparser
// TODO: input config.txt file path
// TODO: merge json files from multiple folders
// TODO: update txt file and logic to handle `supercategory`
// define the path to input json files
let jsonsURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/ANNOTATION_roadmark/FRONT_rect/")
let imageURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/IMAGE/FRONT_rect")
let datasetConfigURL = URL(fileURLWithPath: "/workspaces/swift/swift_coco/Config/axera_roadMarking_trafficLight_trafficSign.txt")
// define the path to output json files
let output_cocoURL = URL(fileURLWithPath: "/code/gaoyi_dataset/coco/aXcellent_roadmark_FRONT_rect/annotations/all_roadmark_trafficSign_trafficLight_withoutNegatives.json")

// create the output coco directory and file
do {
    try FileManager.default.createDirectory(at: output_cocoURL, withIntermediateDirectories: true, attributes: nil)
} catch {
    print(error)
}

var coco_json = createDefaultCocoJson(datasetConfigURL: datasetConfigURL)

// iter through jsonsURL to read json files
let decoder = JSONDecoder()
let jsons = try FileManager.default.contentsOfDirectory(at: jsonsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
let sortedJSONs = jsons.sorted { url1, url2 -> Bool in
    url1.lastPathComponent < url2.lastPathComponent
}

// TODO: status bar
var categoryCounter = [String: Int]()
let total = sortedJSONs.count
print("Processing \(total) items...")
for (index, json) in sortedJSONs.enumerated() {
    let progress = Float(index + 1) / Float(total)
    print("\rProgress: \(progress * 100)%", terminator: "")

    let axera_json = try! String(contentsOf: json)
    if let axeraData = axera_json.data(using: .utf8) {
        do {
            let axera_img_anno = try decoder.decode(AxeraImageAnno.self, from: axeraData)
            if axera_img_anno.instances.count == 0 {
                continue
            }

            // add image entry toto coco json
            let cocoImage = CocoImage(
                id: coco_json.images.count,
                license: 0,
                file_name: "",
                height: axera_img_anno.frames[0].frames[0].imageHeight,
                width: axera_img_anno.frames[0].frames[0].imageWidth,
                date_captured: ""
            )
            coco_json.images.append(cocoImage)

            // create a set to store different names
            for inst in axera_img_anno.instances {
                print(inst.children[0].cameras[0].frames[0].shapeType)
                // update counter
                let curCategoryName = inst.categoryName
                if let count = categoryCounter[curCategoryName] {
                    categoryCounter[curCategoryName] = count + 1
                } else {
                    categoryCounter[curCategoryName] = 1
                }

                // create a CocoInstanceAnnotation to add to coco_json
                let cocoInstanceAnnotation = CocoInstanceAnnotation(
                    id: coco_json.annotations.count,
                    image_id: coco_json.images.count,
                    // assign category_id by look up the mapping between id and name in CocoCategory
                    category_id: coco_json.categories[coco_json.categories.firstIndex(where: { $0.name == curCategoryName })!].id,
                    bbox: [0, 0, 0, 0],
                    segmentation: [[0, 0, 0, 0]],
                    area: 0,
                    iscrowd: 0
                )
            }

            // if axera_img_anno.instances[0].categoryName == "停止线" {
            //     print(axera_img_anno.instances[0].children[0].cameras[0].frames[0].shape)
            // }
            // print(axera_img_anno.instances[0].categoryName)

            // print("-----------------------------------------------------")
            // print(axera_img_anno)
            // print("-----------------------------------------------------")
        } catch {
            print("!!!!Current json file path!!!!")
            print(json)
            print("\(error)")
            print("Error: \(error.localizedDescription)")
        }

        // switch axera_img_anno.instances[0].children[0].cameras[0].frames[0].shape {
        // case let .rectangle(rectangle):
        //     print(rectangle.x)
        // default: // TODO: other cases
        //     break
        // }
    }
    // if index > 200 {
    //     break
    // }
}

print("\nDone")
print("--------------------------------------------------------------------------------")
print("Instance Count for each Category")
print(categoryCounter)
