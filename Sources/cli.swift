import ArgumentParser
import Crypto
import Foundation

// TODO: logging enable

@main
struct SwiftCOCO: ParsableCommand {
    @Option(help: "Specify the input type: `2D` Axera(Traffic light, etc) data or `3D` Axera data(Car, Lane, etc)")
    public var type: String
    @Option(help: "The paths to input json files, split by space")
    public var axeraAnnoPath: [String]
    @Option(help: "The path to input image files")
    public var axeraImgPath: String
    @Option(help: "The path to ouput coco-json files")
    public var outJsonPath: String

    public func run() throws {
        body(type: type, axeraAnnoPath: axeraAnnoPath, axeraImgPath: axeraImgPath)
    }

    private func body(type: String, axeraAnnoPath: [String], axeraImgPath: String) {
        switch type {
        case "2D":
            convert2D(axeraAnnoPath: axeraAnnoPath, axeraImgPath: axeraImgPath)
        case "3D":
            convert3D(axeraAnnoPath: axeraAnnoPath, axeraImgPath: axeraImgPath)
        default:
            print("Invalid type")
        }
    }

    private func convert3D(axeraAnnoPath: [String], axeraImgPath: String) {
        // not implemented:
        print("Not implemented")

    }

    private func convert2D(axeraAnnoPath: [String], axeraImgPath: String) {
        var jsonsURLs = [URL]()
        for path in axeraAnnoPath {
            jsonsURLs.append(URL(fileURLWithPath: path))
        }
        // jsonsURLs.append(URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/axera_manu_v1.0/ANNOTATION_ROADMARK/FRONT_WIDE_rect/"))
        // jsonsURLs.append(URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/axera_manu_v1.0/ANNOTATION_ROADMARK/FRONT_rect/"))
        let imageURL = URL(fileURLWithPath: axeraImgPath)
        // let imageURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/axera_manu_v1.0/IMAGE/FRONT_rect")
        // let xpilotImageURL = URL(fileURLWithPath: "/data/dataset/aXcellent/manu-label/axera_manu_v1.0/IMAGE/FRONT_WIDE_rect")
        // let output_cocoURL = URL(fileURLWithPath: "/code/gaoyi_dataset/coco/aXcellent_roadmark_FRONT_rect/annotations/all_FRONT_rect_rm_1108_Xpilot_Xfv.json")
        let output_cocoURL = URL(fileURLWithPath: outJsonPath)
        let parentDirectoryURL = output_cocoURL.deletingLastPathComponent()

        let decoder = JSONDecoder()
        let category2id_hashmapURL = URL(fileURLWithPath: "./Config/category2id_hashmap.txt")
        var coco_json = createDefaultCocoJson()
        var supercategoryCounter = [String: Int]()
        var counter: [String: [String: Int]] = [:]
        var file_name2id = [String: Int]()
        var roadArrowtype: Set<String> = []
        var trafficLighttype: Set<String> = []
        var trafficLightColor: Set<String> = []
        var trafficSigntype: Set<String> = []

        var childrenTFLCounter: [String: Int] = [:]
        var childrenTFSCounter: [String: Int] = [:]

        var childrenTFLcolorCounter: [String: Int] = [:]
        var childrenTFLImageCounter = 0
        var childrenTFSTypeCounter: [String: Int] = [:]
        var childrenTFSImageCounter = 0

        do {
            try FileManager.default.createDirectory(at: parentDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating parent directory for output: \(error)")
        }

        // load category2id_hashmap
        var category2id_hashmap: [String: (String, Int)] = [:]
        if let category2id_hashmapData = try? String(contentsOf: category2id_hashmapURL) {
            let lines = category2id_hashmapData.components(separatedBy: .newlines)
            for line in lines {
                let fields = line.components(separatedBy: "\t")
                if fields.count != 3 {
                    continue
                }
                category2id_hashmap[fields[0]] = (fields[1], Int(fields[2])!)
            }
        }

        print("Processing items...")
        for (jsonFileCount, jsonsURL) in jsonsURLs.enumerated() {
            // choose imgageURL by check if `jsonsURL` have `WIDE` in his path string
            // TODO: better logic to assign json annotion to xfv/xpilot
            let imageURL = jsonsURL.lastPathComponent.contains("WIDE") ? "FRONT_WIDE_rect" : "FRONT_rect"
            print("Processing item \(jsonFileCount + 1) of total \(jsonsURLs.count) given json source")
            let jsons: [URL]
            do {
                jsons = try FileManager.default.contentsOfDirectory(at: jsonsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            } catch {
                print("\(error) when loading \(jsonsURL)")
                fatalError("Error loading data")
            }

            let total = jsons.count
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
                        var Marker = false
                        var Marker2 = false
                        for inst in axera_img_anno.instances {
                            let supercategoryName = inst.categoryName
                            // TODO: intergreate this swich syntax to logging system
                            switch supercategoryName {
                            case "路面箭头":
                                if let RAtype = inst.attributes?["type"], RAtype != "unknown" {
                                    roadArrowtype.insert(RAtype)
                                }
                            case "交通灯":
                                if let TFLtype = inst.attributes?["type"], TFLtype != "unknown" {
                                    trafficLighttype.insert(TFLtype)
                                    trafficLightColor.insert(inst.attributes?["color"] ?? "unknown")
                                }
                            case "交通标志":
                                if let TFStype = inst.attributes?["类型"], TFStype != "unknown" {
                                    trafficSigntype.insert(TFStype)
                                }
                            default:
                                break
                            }

                            if ["交通灯"].contains(supercategoryName),
                               inst.children[0].cameras[0].frames[0].attributes?["color"] != nil
                            {
                                let tmp = inst.children[0].cameras[0].frames[0].attributes?["color"] ?? "unknown"
                                if tmp != "unknown" {
                                    Marker = true
                                }

                                let curType = inst.children[0].cameras[0].frames[0].attributes?["type"] ?? "unknown"
                                let tmpName = "Type_" + curType + "_Color_" + (inst.children[0].cameras[0].frames[0].attributes?["color"] ?? "default_color")
                                if let count = childrenTFLCounter[tmpName] {
                                    childrenTFLCounter[tmpName] = count + 1
                                } else {
                                    childrenTFLCounter[tmpName] = 1
                                }

                                if let count = childrenTFLcolorCounter[inst.children[0].cameras[0].frames[0].attributes?["color"] ?? "unknown"] {
                                    childrenTFLcolorCounter[inst.children[0].cameras[0].frames[0].attributes?["color"] ?? "unknown"] = count + 1
                                } else {
                                    childrenTFLcolorCounter[inst.children[0].cameras[0].frames[0].attributes?["color"] ?? "unknown"] = 1
                                }
                            }
                            if ["交通标志"].contains(supercategoryName),
                               inst.children[0].cameras[0].frames[0].attributes?["type"] != nil
                            {
                                let tmp = inst.children[0].cameras[0].frames[0].attributes?["type"] ?? "unknown"
                                if tmp != "unknown" {
                                    Marker2 = true
                                }
                                let curType = (inst.children[0].cameras[0].frames[0].attributes?["type"] ?? "unknown")
                                if let count = childrenTFSCounter[curType] {
                                    childrenTFSCounter[curType] = count + 1
                                } else {
                                    childrenTFSCounter[curType] = 1
                                }

                                if let count = childrenTFSTypeCounter[(inst.children[0].cameras[0].frames[0].attributes?["type"] ?? "unknown")] {
                                    childrenTFSTypeCounter[(inst.children[0].cameras[0].frames[0].attributes?["type"] ?? "unknown")] = count + 1
                                } else {
                                    childrenTFSTypeCounter[(inst.children[0].cameras[0].frames[0].attributes?["type"] ?? "unknown")] = 1
                                }
                            }

                            // skip if a supercategory that should have sub attributes, but attributes is nil
                            if ["交通灯", "路面箭头", "交通标志"].contains(supercategoryName), inst.attributes == nil {
                                continue
                            }

                            let categoryName = supercategory2category(supercategory: supercategoryName, type: inst.attributes?["type"] ?? "unknown", color: inst.attributes?["color"] ?? "unknown", typeCN: inst.attributes?["类型"] ?? "unknown")
                            if categoryName == "unknown" {
                                continue
                            } else {
                                counter[supercategoryName] = counter[supercategoryName] ?? [:]
                                counter[supercategoryName]![categoryName] = (counter[supercategoryName]![categoryName] ?? 0) + 1
                            }
                            if let count = supercategoryCounter[supercategoryName] {
                                supercategoryCounter[supercategoryName] = count + 1
                            } else {
                                supercategoryCounter[supercategoryName] = 1
                            }

                            // create category entry if not exist
                            var curCategoryId = coco_json.categories.first(where: { $0.name == categoryName })?.id
                            if curCategoryId == nil {
                                if category2id_hashmap[categoryName] != nil {
                                    curCategoryId = category2id_hashmap[categoryName]!.1
                                } else {
                                    curCategoryId = coco_json.categories.count
                                    let curCatehash = SHA256.hash(data: categoryName.data(using: .utf8)!)
                                    // save the hexdigit string format of curCatehash
                                    let hexHash = curCatehash.compactMap { String(format: "%02x", $0) }.joined()
                                    category2id_hashmap[categoryName] = (hexHash, curCategoryId!)
                                }
                                coco_json.categories.append(CocoCategory(id: curCategoryId!, name: categoryName, supercategory: supercategoryName))
                            }

                            // create image entry if not exist
                            let file_path = imageURL + "/" + cur_json.deletingPathExtension().appendingPathExtension("jpg").lastPathComponent
                            if file_name2id[file_path] == nil {
                                file_name2id[file_path] = coco_json.images.count
                                var axera_img_anno_height: Int
                                var axera_img_anno_width: Int
                                if let axera_img_anno_frames = axera_img_anno.frames[0].frames {
                                    axera_img_anno_height = axera_img_anno_frames[0].imageHeight
                                    axera_img_anno_width = axera_img_anno_frames[0].imageWidth
                                } else {
                                    fatalError("Failed to find filed `frames[0].frames[0]` in axerao annotion, which is required for type=2D")
                                }
                                let cocoImage = createImageEntry(
                                    image_id: file_name2id[file_path]!,
                                    file_name: file_path, // last two path component
                                    height: axera_img_anno_height,
                                    width: axera_img_anno_width
                                )
                                coco_json.images.append(cocoImage)
                            }

                            let coco_anno_seg = extractCocoSeg(axera_inst: inst)
                            let coco_anno_bbox = calBboxFromCocoSeg(polygon_points_array: coco_anno_seg)
                            let cur_box_area = coco_anno_bbox[2] * coco_anno_bbox[3]

                            let cocoInstanceAnnotation = CocoInstanceAnnotation(
                                id: coco_json.annotations.count,
                                image_id: file_name2id[file_path]!,
                                category_id: curCategoryId!,
                                bbox: coco_anno_bbox,
                                segmentation: coco_anno_seg,
                                area: cur_box_area,
                                iscrowd: 0
                            )
                            coco_json.annotations.append(cocoInstanceAnnotation)
                        }

                        if Marker {
                            childrenTFLImageCounter += 1
                            Marker = false
                        }
                        if Marker2 {
                            childrenTFSImageCounter += 1
                            Marker = false
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

        let fileHandle = try! FileHandle(forWritingTo: category2id_hashmapURL)
        // delete all contents of target URL
        fileHandle.truncateFile(atOffset: 0)

        // sort category2id_hashmap and save category2id_hashmap, each element take up one line
        for (key, value) in category2id_hashmap.sorted(by: { $0.value.1 < $1.value.1 }) {
            let line = "\(key)\t\(value.0)\t\(value.1)\n"
            fileHandle.seekToEndOfFile()
            fileHandle.write(line.data(using: .utf8)!)
        }

        fileHandle.closeFile()

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
            if let trafficSignCounter = counter["交通标志"], trafficSignCounter["TFS_" + i] == nil {
                counter["交通标志"]!["TFS_" + i] = 0
            }
        }

        print("\n-------------------Done----------------------------------------------")
        // check if output_cocoURL exists
        if FileManager.default.fileExists(atPath: output_cocoURL.path) {
            let cocoFileHandle = try! FileHandle(forWritingTo: output_cocoURL)
            do {
                try cocoFileHandle.truncate(atOffset: 0) // clear contents
            } catch {
                print("Error when truncate \(output_cocoURL)")
                fatalError("Error: \(error.localizedDescription)")
            }

            do {
                try cocoFileHandle.close()
            } catch {
                print("Error when close \(output_cocoURL)")
                fatalError("Error: \(error.localizedDescription)")
            }
        }

        do {
            try JSONEncoder().encode(coco_json).write(to: output_cocoURL)
        } catch {
            print("Error when encode \(output_cocoURL)")
            fatalError("Error: \(error.localizedDescription)")
        }

        print("saved to \(output_cocoURL)\n")

        print("\n-------------------Supercategory Insight----------------------------------------------")
        print("road_arrow types: \(roadArrowtype)\n")
        print("traffic_light types: \(trafficLighttype)")
        print("traffic_light color: \(trafficLightColor)\n")
        print("traffic_sign type: \(trafficSigntype)")

        print("\n-------------------Summary----------------------------------------------")
        // check how many images in imageURL
        let images: [URL]
        do {
        images = try FileManager.default.contentsOfDirectory(at: imageURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
        } catch {
            print(error)
            fatalError("Error loading image directores")
        }
        let total_images = images.count
        print("Total \(total_images) images in \(imageURL.absoluteURL)\n")

        for jsonsURL in jsonsURLs {
            // print the count of files in jsonsURL
            let jsons: [URL]
            do {
            jsons = try FileManager.default.contentsOfDirectory(at: jsonsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            } catch {
                print(error)
                fatalError("Error loading json directory")
            }
            let total = jsons.count
            print("Total \(total) json files in \(jsonsURL.absoluteURL)")
        }

        print("\nTotal \(coco_json.images.count) images have annotations")
        print("\nInstance Count for each Supercategory")
        print(supercategoryCounter)

        print("\nInstance Count for each Category")
        for (key, value) in counter {
            print("\(key): \(value)")
        }

        print("")
        print("Total TFL children images: \(childrenTFLImageCounter)")
        print("children TFL color counter")
        for item in childrenTFLcolorCounter.sorted(by: { $0.0 > $1.0 }) {
            print("\(item.0): \(item.1)")
        }

        print("")
        print("Total TFS images children: \(childrenTFSImageCounter)")
        print("children TFS type counter")
        for item in childrenTFSTypeCounter.sorted(by: { $0.0 > $1.0 }) {
            if ["il100",
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
                "pr60",
                "unknown"].contains(item.0)
            {
                print("\(item.0): \(item.1)")
            }
        }
    }
}
