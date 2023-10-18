import Foundation
// TODO: pass by reference?
func extractCocoSeg(axera_inst: AxeraInstance) -> [[Double]] {
    var polygon_points_array = [[Double]]()
    for child in axera_inst.children {
        var curSeg = [Double]()
        switch child.cameras[0].frames[0].shape {
        case let .rectangle(rect):
            for point in rect.points {
                curSeg.append(point.x)
                curSeg.append(point.y)
            }
        case let .polygon(poly):
            for point in poly.points {
                curSeg.append(point.x)
                curSeg.append(point.y)
            }
        case let .line(line):
            for point in line.points {
                curSeg.append(point.x)
                curSeg.append(point.y)
            }

        default:
            // TODO:
            print("error")
        }
        polygon_points_array.append(curSeg)
    }
    return polygon_points_array
}

func calBboxFromCocoSeg(polygon_points_array:[[Double]]) -> [Double] {
    guard let firstFragment = polygon_points_array.first else {
        return []
    }

    var minX = firstFragment[0]
    var minY = firstFragment[1]
    var maxX = firstFragment[0]
    var maxY = firstFragment[1]

    for fragment in polygon_points_array {
        for i in stride(from: 0, to: fragment.count, by: 2) {
            let x = fragment[i]
            let y = fragment[i + 1]

            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
    return [minX, minY, maxX-minX, maxY-minY]
}

func extractCn2EngNameMapping(dataasetConfigURL: URL) -> [String: String] {
    // parse category
    var nameMapping = [String: String]()
    let fileContents = try! String(contentsOf: datasetConfigURL)
    let lines = fileContents.components(separatedBy: "\n")
    for line in lines {
        let parts = line.split(separator: " ")
        let CNname = String(parts[1])
        let ENGname = String(parts[2])
        nameMapping[CNname] = ENGname
    }
    return nameMapping
}

func createDefaultCocoJson(datasetConfigURL: URL) -> CocoAnno {
    var coco_categories = [CocoCategory]()
    // parse category
    let fileContents = try! String(contentsOf: datasetConfigURL)
    let lines = fileContents.components(separatedBy: "\n")
    for line in lines {
        let parts = line.split(separator: " ")
        let id = Int(parts[0])!
        let name = String(parts[2])

        let category = CocoCategory(id: id, name: name, supercategory: "")
        coco_categories.append(category)
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let currentTimeString = dateFormatter.string(from: Date())

    let coco_info = CocoInfo(
        year: "2023",
        version: "0.1",
        description: "",
        contributor: "goooyi",
        url: "https://github.com/Goooyi/swift_coco",
        date_created: currentTimeString
    )

    let coco_license = CocoLicense(
        url: "",
        id: 0,
        name: ""
    )

    let coco_anno = CocoAnno(
        info: coco_info,
        licenses: [coco_license],
        categories: coco_categories,
        images: [],
        annotations: []
    )
    return coco_anno
}
