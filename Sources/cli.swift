import ArgumentParser
import Crypto
import Foundation
import PythonKit

// TODO: logging enable

@main
struct SwiftCOCO: ParsableCommand {
    @Option(help: "Specify the input type: `2D` Axera(Traffic light, etc) data or `3D` Axera data(Car, Lane, etc)")
    public var type: String
    @Option(help: "If type=3D, this option is required, otherwise it will be ignored. Specify the scaling type when type=3D: `2D`  or `3D` ")
    public var scalingType: String
    @Option(help: "The paths to camera yaml file")
    public var cameraYamlPath: String
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
            convert3D(axeraAnnoPath: axeraAnnoPath, axeraImgPath: axeraImgPath, scalingType: scalingType)
        default:
            print("Invalid type")
        }
    }

    private func convert3D(axeraAnnoPath: [String], axeraImgPath _: String, scalingType: String) {
        print("Processing 3D annotations")
        var jsonsURLs = [URL]()
        for path in axeraAnnoPath {
            jsonsURLs.append(URL(fileURLWithPath: path))
        }
        // let imageURL = URL(fileURLWithPath: axeraImgPath)
        let output_cocoURL = URL(fileURLWithPath: outJsonPath)
        let parentDirectoryURL = output_cocoURL.deletingLastPathComponent()

        let decoder = JSONDecoder()
        let category2id_hashmapURL = URL(fileURLWithPath: "./Config/category2id_hashmap.txt")
        var coco_json = createDefaultCocoJson()
        var counter: [String: [String: Int]] = [:]
        var file_name2id = [String: Int]()

        do {
            try FileManager.default.createDirectory(at: parentDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating parent directory for output: \(error)")
        }

        var np = Python.import("numpy")
        var tan = Python.import("math").tan
        var pi = Python.import("math").pi
        var yaml = Python.import("yaml")
        var FrontCameraMatrix = PythonObject([])
        var frontCamIntrinsics = PythonObject([])
        let cameraYaml = try! String(contentsOf: URL(fileURLWithPath: cameraYamlPath))
        let cameraYamlDict = try! yaml.safe_load(cameraYaml)
        for camera in cameraYamlDict["camera"] {
            let camera_config = camera["camera_config"]
            if camera_config["topic"] == "/camera/XFV/FRONT/compressed_image" {
                FrontCameraMatrix = camera_config["tovcs"]
                frontCamIntrinsics = camera_config["intrinsics"]
            }
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
            var jsons: [URL]
            do {
                jsons = try FileManager.default.contentsOfDirectory(at: jsonsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
            } catch {
                print("\(error) when loading \(jsonsURL)")
                fatalError("Error loading data")
            }

            // // take only the first 100
            // jsons = Array(jsons[0..<1000])
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
                        if axera_img_anno.frames.count == 0 {
                            continue
                        }

                        // create a set to store different names
                        // acutally all axera_img_ann.frames has only one inside
                        for frame in axera_img_anno.frames {
                            if scalingType == "3D" {
                                // read yaml file
                                for frameItem in frame.items! {
                                    let labelsObj = frameItem.labelsObj
                                    if labelsObj == nil {
                                        continue
                                    }
                                    if labelsObj!.visibility == "0% - 30%" {
                                        continue
                                    }
                                    let bbox2d_8p = pytest(frameItem: frameItem,
                                                           FrontCameraMatrix: &FrontCameraMatrix,
                                                           fov_w: 100,
                                                           frontCamIntrinsics: &frontCamIntrinsics,
                                                           np: &np,
                                                           tan: &tan,
                                                           pi: &pi,
                                                           yaml: &yaml)

                                    if bbox2d_8p.count == 0 {
                                        continue
                                    }
                                    // create image entry if not exist
                                    let file_path = imageURL + "/" + cur_json.deletingPathExtension().appendingPathExtension("jpg").lastPathComponent
                                    if file_name2id[file_path] == nil {
                                        file_name2id[file_path] = coco_json.images.count
                                        let axera_img_anno_height = 1080
                                        let axera_img_anno_width = 1920
                                        let cocoImage = createImageEntry(
                                            image_id: file_name2id[file_path]!,
                                            file_name: file_path, // last two path component
                                            height: axera_img_anno_height,
                                            width: axera_img_anno_width
                                        )
                                        coco_json.images.append(cocoImage)
                                    }
                                    // count categories and supercategories
                                    let separators = CharacterSet(charactersIn: "_. ")
                                    let nameSeq = frameItem.category.components(separatedBy: separators)
                                    let supercategory = nameSeq[0]
                                    let category = nameSeq[1]
                                    if counter.keys.contains(String(supercategory)) {
                                        if counter[String(supercategory)]!.keys.contains(String(category)) {
                                            counter[String(supercategory)]![String(category)]! += 1
                                        } else {
                                            counter[String(supercategory)]![String(category)] = 1
                                        }
                                    } else {
                                        counter[String(supercategory)] = [String(category): 1]
                                    }
                                    // create category entry if not exist
                                    var curCategoryId = coco_json.categories.first(where: { $0.name == category })?.id
                                    if curCategoryId == nil {
                                        if category2id_hashmap[category] != nil {
                                            curCategoryId = category2id_hashmap[category]!.1
                                        } else {
                                            curCategoryId = coco_json.categories.count
                                            let curCatehash = SHA256.hash(data: category.data(using: .utf8)!)
                                            // save the hexdigit string format of curCatehash
                                            let hexHash = curCatehash.compactMap { String(format: "%02x", $0) }.joined()
                                            category2id_hashmap[category] = (hexHash, curCategoryId!)
                                        }
                                        coco_json.categories.append(CocoCategory(id: curCategoryId!, name: category, supercategory: supercategory))
                                    }
                                    // create coco instance
                                    var cur_box_x_max = bbox2d_8p[0].x
                                    var cur_box_y_max = bbox2d_8p[0].y
                                    var cur_box_x_min = bbox2d_8p[0].x
                                    var cur_box_y_min = bbox2d_8p[0].y
                                    for i in 0 ..< 8 {
                                        if bbox2d_8p[i].x < cur_box_x_min {
                                            cur_box_x_min = bbox2d_8p[i].x
                                        }
                                        if bbox2d_8p[i].x > cur_box_x_max {
                                            cur_box_x_max = bbox2d_8p[i].x
                                        }
                                        if bbox2d_8p[i].y < cur_box_y_min {
                                            cur_box_y_min = bbox2d_8p[i].y
                                        }
                                        if bbox2d_8p[i].y > cur_box_y_max {
                                            cur_box_y_max = bbox2d_8p[i].y
                                        }
                                    }
                                    var coco_anno_seg = [[Double]]()
                                    var curSeg = [Double]()
                                    curSeg.append(cur_box_x_min)
                                    curSeg.append(cur_box_y_min)
                                    curSeg.append(cur_box_x_max)
                                    curSeg.append(cur_box_y_min)
                                    curSeg.append(cur_box_x_max)
                                    curSeg.append(cur_box_y_max)
                                    curSeg.append(cur_box_x_min)
                                    curSeg.append(cur_box_y_max)
                                    coco_anno_seg.append(curSeg)
                                    let cur_box_area = (cur_box_x_max - cur_box_x_min) * (cur_box_y_max - cur_box_y_min)
                                    let cocoInstanceAnnotation = CocoInstanceAnnotation(
                                        id: coco_json.annotations.count,
                                        image_id: file_name2id[file_path]!,
                                        category_id: curCategoryId!,
                                        bbox: [cur_box_x_min, cur_box_y_min, cur_box_x_max - cur_box_x_min, cur_box_y_max - cur_box_y_min],
                                        segmentation: coco_anno_seg,
                                        area: cur_box_area,
                                        iscrowd: 0
                                    )
                                    coco_json.annotations.append(cocoInstanceAnnotation)
                                }
                            } else {
                                for img in frame.images! {
                                    if !img.image.contains("FRONT_rect") {
                                        continue
                                    }
                                    // create image entry if not exist
                                    let file_path = imageURL + "/" + cur_json.deletingPathExtension().appendingPathExtension("jpg").lastPathComponent
                                    if file_name2id[file_path] == nil {
                                        file_name2id[file_path] = coco_json.images.count
                                        let axera_img_anno_height = img.height
                                        let axera_img_anno_width = img.width
                                        let cocoImage = createImageEntry(
                                            image_id: file_name2id[file_path]!,
                                            file_name: file_path, // last two path component
                                            height: axera_img_anno_height,
                                            width: axera_img_anno_width
                                        )
                                        coco_json.images.append(cocoImage)
                                    }

                                    for item in img.items {
                                        // TODO: clean seperator when annotated
                                        if !visibleFor3DImageItem(axera_inst: item, axera_items: frame.items!) {
                                            continue
                                        }
                                        // count categories and supercategories
                                        let separators = CharacterSet(charactersIn: "_. ")
                                        let nameSeq = item.category.components(separatedBy: separators)
                                        let supercategory = nameSeq[0]
                                        let category = nameSeq[1]
                                        if counter.keys.contains(String(supercategory)) {
                                            if counter[String(supercategory)]!.keys.contains(String(category)) {
                                                counter[String(supercategory)]![String(category)]! += 1
                                            } else {
                                                counter[String(supercategory)]![String(category)] = 1
                                            }
                                        } else {
                                            counter[String(supercategory)] = [String(category): 1]
                                        }

                                        // create category entry if not exist
                                        var curCategoryId = coco_json.categories.first(where: { $0.name == category })?.id
                                        if curCategoryId == nil {
                                            if category2id_hashmap[category] != nil {
                                                curCategoryId = category2id_hashmap[category]!.1
                                            } else {
                                                curCategoryId = coco_json.categories.count
                                                let curCatehash = SHA256.hash(data: category.data(using: .utf8)!)
                                                // save the hexdigit string format of curCatehash
                                                let hexHash = curCatehash.compactMap { String(format: "%02x", $0) }.joined()
                                                category2id_hashmap[category] = (hexHash, curCategoryId!)
                                            }
                                            coco_json.categories.append(CocoCategory(id: curCategoryId!, name: category, supercategory: supercategory))
                                        }

                                        // create coco instance
                                        let coco_anno_seg = extract3DCocoSeg(axera_inst: item, width: img.width, height: img.height)
                                        var cur_box_x_min = coco_anno_seg[0][0]
                                        var cur_box_y_min = coco_anno_seg[0][1]
                                        var cur_box_x_max = coco_anno_seg[0][0]
                                        var cur_box_y_max = coco_anno_seg[0][1]
                                        for i in stride(from: 2, to: coco_anno_seg[0].count, by: 2) {
                                            if coco_anno_seg[0][i] < cur_box_x_min {
                                                cur_box_x_min = coco_anno_seg[0][i]
                                            }
                                            if coco_anno_seg[0][i] > cur_box_x_max {
                                                cur_box_x_max = coco_anno_seg[0][i]
                                            }
                                            if coco_anno_seg[0][i + 1] < cur_box_y_min {
                                                cur_box_y_min = coco_anno_seg[0][i + 1]
                                            }
                                            if coco_anno_seg[0][i + 1] > cur_box_y_max {
                                                cur_box_y_max = coco_anno_seg[0][i + 1]
                                            }
                                        }
                                        let cur_box_area = (cur_box_x_max - cur_box_x_min) * (cur_box_y_max - cur_box_y_min)
                                        let cocoInstanceAnnotation = CocoInstanceAnnotation(
                                            id: coco_json.annotations.count,
                                            image_id: file_name2id[file_path]!,
                                            category_id: curCategoryId!,
                                            bbox: [cur_box_x_min, cur_box_y_min, cur_box_x_max - cur_box_x_min, cur_box_y_max - cur_box_y_min],
                                            segmentation: coco_anno_seg,
                                            area: cur_box_area,
                                            iscrowd: 0
                                        )
                                        coco_json.annotations.append(cocoInstanceAnnotation)
                                    }
                                }
                            }
                        }
                    } catch {
                        print("Error when decode \(cur_json)")
                        print("\(error)")
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
        print("")
        for supercategory in counter {
            print(supercategory.key)
            for category in supercategory.value {
                print("\t\(category.key): \(category.value)")
            }
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

        // check if output_cocoURL exists and save output
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
    }

    private func convert2D(axeraAnnoPath: [String], axeraImgPath: String) {
        print("Processing 2D annotations")
        var jsonsURLs = [URL]()
        for path in axeraAnnoPath {
            jsonsURLs.append(URL(fileURLWithPath: path))
        }
        let imageURL = URL(fileURLWithPath: axeraImgPath)
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
                        if let axInstances = axera_img_anno.instances, axInstances.count == 0 {
                            continue
                        }

                        // create a set to store different names
                        for inst in axera_img_anno.instances! {
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

                            // if ["交通灯"].contains(supercategoryName),
                            //    inst.children[0].cameras[0].frames[0].attributes?["color"] != nil
                            // {
                            //     let tmp = inst.children[0].cameras[0].frames[0].attributes?["color"] ?? "unknown"
                            //     if tmp != "unknown" {
                            //         Marker = true
                            //     }

                            // }
                            // if ["交通标志"].contains(supercategoryName),
                            //    inst.children[0].cameras[0].frames[0].attributes?["type"] != nil
                            // {
                            //     let tmp = inst.children[0].cameras[0].frames[0].attributes?["type"] ?? "unknown"
                            //     if tmp != "unknown" {
                            //         Marker2 = true
                            //     }
                            // }

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
    }
}
