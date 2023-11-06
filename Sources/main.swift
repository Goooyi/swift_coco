import Foundation

// TODO: argparser
// TODO: input config.txt file path
// TODO: FRONT_rect vs Wide
// define the path to input json files
var jsonsURLs = [URL]()
jsonsURLs.append(URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/axera_manu_v1.0/ANNOTATION_ROADMARK/FRONT_rect/"))
jsonsURLs.append(URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/axera_manu_v1.0/ANNOTATION_TRAFFIC/FRONT_rect/"))
let decoder = JSONDecoder()

let imageURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/axera_manu_v1.0/IMAGE/FRONT_rect")
let datasetConfigURL = URL(fileURLWithPath: "/workspaces/swift/swift_coco/Config/axera_roadMarking_trafficLight_trafficSign.txt")
let output_cocoURL = URL(fileURLWithPath: "/code/gaoyi_dataset/coco/aXcellent_roadmark_FRONT_rect/annotations/all_FRONT_rect_RM_tfs_tfl_1106.json")
let parentDirectoryURL = output_cocoURL.deletingLastPathComponent()

let nameMapping = extractCn2EngNameMapping(datasetConfigURL: datasetConfigURL)
var coco_json = createDefaultCocoJson(datasetConfigURL: datasetConfigURL)

do {
    try FileManager.default.createDirectory(at: parentDirectoryURL, withIntermediateDirectories: true, attributes: nil)
} catch {
    print("Error creating parent directory: \(error)")
}

var supercategoryCounter = [String: Int]()

var TFLCategoryCounter = [String: Int]()
var TFSCategoryCounter = [String: Int]()
var RMCategoryCounter = [String: Int]()
var file_name2id = [String: Int]()

var roadArrowtype: Set<String> = []
var trafficLighttype: Set<String> = []
var trafficLightColor: Set<String> = []
var trafficSigntype: Set<String> = []

var Counter: [String: [String: Int]] = [:]

// TODO: status bar
print("Processing items...")
for (jsonFileCount, jsonsURL) in jsonsURLs.enumerated() {
    print("Processing item \(jsonFileCount + 1) of total \(jsonsURLs.count) given json source")
    let jsons = try FileManager.default.contentsOfDirectory(at: jsonsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
    let total = jsons.count
    // let sortedJSONs = jsons.sorted { url1, url2 -> Bool in url1.lastPathComponent < url2.lastPathComponent }
    for (index, cur_json) in jsons.enumerated() {
        let progress = Float(index + 1) / Float(total)
        let formattedProgress = String(format: "%.2f", progress * 100)
        print("\rProgress: \(formattedProgress)%", terminator: "")

        let axera_json = try! String(contentsOf: cur_json)
        if let axeraData = axera_json.data(using: .utf8) {
            do {
                // skip if no anno for this image
                let axera_img_anno = try decoder.decode(AxeraImageAnno.self, from: axeraData)
                if axera_img_anno.instances.count == 0 {
                    continue
                }

                // TODO: for now if all instance of this image is type:unkown, the cocoImage will not be added
                // create a set to store different names
                for inst in axera_img_anno.instances {
                    // TODO：to delete, only for debug
                    if inst.categoryName == "路面箭头" {
                        if let RAtype = inst.attributes?["type"], RAtype != "unknown" {
                            roadArrowtype.insert(RAtype)
                        }
                    }

                    if inst.categoryName == "交通灯" {
                        if let TFLtype = inst.attributes?["type"], TFLtype != "unknown" {
                            trafficLighttype.insert(TFLtype)
                            trafficLightColor.insert(inst.attributes?["color"] ?? "unknown")
                        }
                    }

                    if inst.categoryName == "交通标志" {
                        if let TFStype = inst.attributes?["类型"], TFStype != "unknown" {
                            trafficSigntype.insert(TFStype)
                        }
                    }

                    // skip if a supercategory that should have sub atttributes, but attributes is nil
                    if ["交通灯", "路面箭头", "交通标志"].contains(inst.categoryName), inst.attributes == nil {
                        continue
                    }
                    // only save those defined in supercategory2category
                    let cate = supercategory2category(supercategory: inst.categoryName, type: inst.attributes?["type"] ?? "unknown", color: inst.attributes?["color"] ?? "unknown", typeCN: inst.attributes?["类型"] ?? "unknown")
                    if cate == "unknown" {
                        continue
                    } else {
                        Counter[inst.categoryName] = Counter[inst.categoryName] ?? [:]
                        Counter[inst.categoryName]![cate] = (Counter[inst.categoryName]![cate] ?? 0) + 1
                    }
                    // if (inst.categoryName == "交通灯") &&  ["red", "yellow", "green"].contains(inst.attributes?["color"]) {
                    //     continue
                    // }
                    // create image entry if not exist
                    let file_path = imageURL.appendingPathComponent(cur_json.deletingPathExtension().appendingPathExtension("jpg").lastPathComponent)
                    if file_name2id[file_path.path] == nil {
                        file_name2id[file_path.path] = coco_json.images.count
                        let cocoImage = createImageEntry(
                            image_id: file_name2id[file_path.path]!,
                            file_name: file_path.path,
                            height: axera_img_anno.frames[0].frames[0].imageHeight,
                            width: axera_img_anno.frames[0].frames[0].imageWidth
                        )
                        coco_json.images.append(cocoImage)
                    }
                    // update counter
                    // TODO: change category according to type
                    let curCategoryName = inst.categoryName
                    if let count = supercategoryCounter[curCategoryName] {
                        supercategoryCounter[curCategoryName] = count + 1
                    } else {
                        supercategoryCounter[curCategoryName] = 1
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
    print("")
}

for i in ["il100",
          "il60",
          "il80",
          "il90",
          "pl100",
          "pl120",
          "pl15",
          "pl20",
          "pl30",
          "pl40",
          "pl5",
          "pl50",
          "pl60",
          "pl70",
          "pl80",
          "pr40",
          "pr60"]
{
    if Counter["交通标志"]![i] == nil {
        Counter["交通标志"]![i] = 0
    }
}

print("\n-------------------Done----------------------------------------------")
print("saved to \(output_cocoURL)\n")
do {
    try JSONEncoder().encode(coco_json).write(to: output_cocoURL)
}

print("\n-------------------Supercategory Insight----------------------------------------------")
print("road_arrow types: \(roadArrowtype)\n")
print("traffic_light types: \(trafficLighttype)")
print("traffic_light color: \(trafficLightColor)\n")
print("traffic_sign type: \(trafficSigntype)")

print("\n-------------------Summary----------------------------------------------")
// check how many images in imageURL
let images = try FileManager.default.contentsOfDirectory(at: imageURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
let total_images = images.count
print("Total \(total_images) images in \(imageURL.absoluteURL)\n")

for jsonsURL in jsonsURLs {
    // print the count of files in jsonsURL
    let jsons = try FileManager.default.contentsOfDirectory(at: jsonsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
    let total = jsons.count
    print("Total \(total) json files in \(jsonsURL.absoluteURL)")
}

print("\nTotal \(coco_json.images.count) images have annotations")
print("\nInstance Count for each Supercategory")
print(supercategoryCounter)

print("\nInstance Count for each Category")
for (key, value) in Counter {
    print("\(key): \(value)")
}
