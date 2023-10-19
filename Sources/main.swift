import Foundation

// TODO: argparser
// TODO: input config.txt file path
// TODO: update txt file and logic to handle `supercategory`
// TODO: FRONT_rect vs Wide
// define the path to input json files
var jsonsURLs = [URL]()
jsonsURLs.append(URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/ANNOTATION_roadmark/FRONT_rect/"))
jsonsURLs.append(URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/ANNOTATION_traffic/FRONT_rect/"))
let decoder = JSONDecoder()

let imageURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/obstacle/IMAGE/FRONT_rect")
let datasetConfigURL = URL(fileURLWithPath: "/workspaces/swift/swift_coco/Config/axera_roadMarking_trafficLight_trafficSign.txt")
let output_cocoURL = URL(fileURLWithPath: "/code/gaoyi_dataset/coco/aXcellent_roadmark_FRONT_rect/annotations/all_FRONT_rect_RM_tfs_tfl.json")
let parentDirectoryURL = output_cocoURL.deletingLastPathComponent()

let nameMapping = extractCn2EngNameMapping(datasetConfigURL: datasetConfigURL)
var coco_json = createDefaultCocoJson(datasetConfigURL: datasetConfigURL)

do {
    try FileManager.default.createDirectory(at: parentDirectoryURL, withIntermediateDirectories: true, attributes: nil)
} catch {
    print("Error creating parent directory: \(error)")
}

var categoryCounter = [String: Int]()
var file_name2id = [String: Int]()

// TODO: status bar
print("Processing items...")
for (jsonFileCount, jsonsURL) in jsonsURLs.enumerated() {
    print("Processing item \(jsonFileCount + 1) of total \(jsonsURLs.count) given json source")
    let jsons = try FileManager.default.contentsOfDirectory(at: jsonsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
    let total = jsons.count
    // let sortedJSONs = jsons.sorted { url1, url2 -> Bool in url1.lastPathComponent < url2.lastPathComponent }
    for (index, cur_json) in jsons.enumerated() {
        let progress = Float(index + 1) / Float(total)
        print("\rProgress: \(progress * 100)%", terminator: "")

        let axera_json = try! String(contentsOf: cur_json)
        if let axeraData = axera_json.data(using: .utf8) {
            do {
                let axera_img_anno = try decoder.decode(AxeraImageAnno.self, from: axeraData)
                if axera_img_anno.instances.count == 0 {
                    continue
                }

                // add image entry toto coco json
                let file_path = imageURL.appendingPathComponent(cur_json.deletingPathExtension().appendingPathExtension("jpg").lastPathComponent)
                if file_name2id[file_path.path] == nil {
                    file_name2id[file_path.path] = coco_json.images.count
                    let cocoImage = CocoImage(
                        id: file_name2id[file_path.path]!,
                        license: 0,
                        file_name: file_path.path,
                        height: axera_img_anno.frames[0].frames[0].imageHeight,
                        width: axera_img_anno.frames[0].frames[0].imageWidth,
                        date_captured: ""
                    )
                    coco_json.images.append(cocoImage)
                }

                // create a set to store different names
                for inst in axera_img_anno.instances {
                    // update counter
                    let curCategoryName = inst.categoryName
                    if let count = categoryCounter[curCategoryName] {
                        categoryCounter[curCategoryName] = count + 1
                    } else {
                        categoryCounter[curCategoryName] = 1
                    }

                    let coco_anno_seg = extractCocoSeg(axera_inst: inst)
                    let coco_anno_bbox = calBboxFromCocoSeg(polygon_points_array: coco_anno_seg)
                    let cur_box_area = coco_anno_bbox[2] * coco_anno_bbox[3]
                    // TODO: as a func
                    let cocoInstanceAnnotation = CocoInstanceAnnotation(
                        id: coco_json.annotations.count,
                        image_id: file_name2id[file_path.path]!,
                        // assign category_id by look up the mapping between id and name in CocoCategory
                        category_id: coco_json.categories[coco_json.categories.firstIndex(where: { $0.name == nameMapping[curCategoryName] })!].id,
                        bbox: coco_anno_bbox,
                        segmentation: coco_anno_seg,
                        area: cur_box_area,
                        iscrowd: 0
                    )
                    coco_json.annotations.append(cocoInstanceAnnotation)
                }
            } catch {
                print("Error when decode \(cur_json)")
                print("\(error)")
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

print("\nsaved to \(output_cocoURL)")
do {
    try JSONEncoder().encode(coco_json).write(to: output_cocoURL)
}

print("Done")
print("--------------------------------------------------------------------------------")
print("Total \(coco_json.images.count) images")
print("Instance Count for each Category")
print(categoryCounter)
