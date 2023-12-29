import Foundation

// function to check if box A inside box B
func checkBox(insA: AxeraInstance, insB: AxeraInstance) -> Bool {
    // calculate intersection
    switch insA.children[0].cameras[0].frames[0].shape {
    case let .rectangle(rectA):
        switch insB.children[0].cameras[0].frames[0].shape {
        case let .rectangle(rectB):
        // check if boxA inside boxB
            if rectA.x >= rectB.x && rectA.y >= rectB.y && rectA.x + rectA.width <= rectB.x + rectB.width && rectA.y + rectA.height <= rectB.y + rectB.height {
                return true
            }
            return false
        default:
            return false
        }
    default:
        return false
    }
}

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
            fatalError("Extract CocoSeg not implemented for this category")
        }
        polygon_points_array.append(curSeg)
    }
    // issue related to cocoapi `https://github.com/cocodataset/cocoapi/issues/139`
    if polygon_points_array[0].count == 4 {
        polygon_points_array[0].append(polygon_points_array[0][0])
        polygon_points_array[0].append(polygon_points_array[0][1])
    }
    return polygon_points_array
}

func visibleFor3DImageItem(axera_inst: AxeraFrame.FrameImages.FrameImagesItem,
                           axera_items: [AxeraFrame.FrameItems]) -> Bool
{
    let id = axera_inst.id
    // find the id in axera_items
    var visibilityStr = "invisible"
    for item in axera_items {
        if item.id == id {
            visibilityStr = item.labelsObj?.visibility ?? "invisible"
        }
    }
    if visibilityStr == "invisible" || visibilityStr.contains("0% - 30%") {
        return false
    } else {
        return true
    }
}

func scaleDown(
    curFrameImagesItemPoints: AxeraFrame.FrameImages.FrameImagesItem.FrameImagesItemPoints,
    width: Int,
    height: Int
) -> (
    x_res: [Double],
    y_res: [Double]
) {
    var x_res = [Double]()
    var y_res = [Double]()
    let count = curFrameImagesItemPoints.x.count
    // find the first point that is inside the frame as scale base
    // TODO: scale down all x,y points that is outside the image, x_base, y_base is the scale base
    for i in 0 ..< count {
        var x_ratio = 1.0
        var y_ratio = 1.0

        let indexIsOdd = i % 2 == 1

        var new_x = curFrameImagesItemPoints.x[i]
        var new_y = curFrameImagesItemPoints.y[i]
        var paired_x = curFrameImagesItemPoints.x[indexIsOdd ? i - 1 : i + 1]
        var paired_y = curFrameImagesItemPoints.y[indexIsOdd ? i - 1 : i + 1]

        if new_x < 0 {
            if paired_x > 0 {
                x_ratio = paired_x / (paired_x - new_x)
                new_x = 0
                new_y = paired_y - ((paired_y - new_y) * x_ratio)
            } else {
                if new_x < paired_x {
                    let tmp_x = paired_x
                    paired_x = new_x
                    new_x = tmp_x
                    let tmp_y = paired_y
                    paired_y = new_y
                    new_y = tmp_y
                }
                x_ratio = paired_x / (paired_x - new_x)
                new_x = 0
                new_y = paired_y + ((new_y - paired_y) * x_ratio)

            }
        } else if new_x > Double(width) {
            x_ratio = (Double(width) - paired_x) / (new_x - paired_x)
            new_x = Double(width)
            new_y = paired_y + ((new_y - paired_y) * x_ratio)
        }
        if new_y < 0 {
            if paired_y > 0 {
            y_ratio = paired_y / (paired_y - new_y)
            new_y = 0
            new_x = paired_x - ((paired_x - new_x) * y_ratio)
            } else {
                if new_y < paired_y {
                    let tmp_x = paired_x
                    paired_x = new_x
                    new_x = tmp_x
                    let tmp_y = paired_y
                    paired_y = new_y
                    new_y = tmp_y
                }
                y_ratio = paired_y / (paired_y - new_y)
                new_y = 0
                new_x = paired_x + ((new_x - paired_x) * y_ratio)
            }
        } else if new_y > Double(height) {
            y_ratio = (Double(height) - paired_y) / (new_y - paired_y)
            new_y = Double(height)
            new_x = paired_x + ((new_x - paired_x) * y_ratio)
        }

        x_res.append(new_x)
        y_res.append(new_y)
    }
    return (x_res, y_res)
}

func extract3DCocoSeg(axera_inst: AxeraFrame.FrameImages.FrameImagesItem, width: Int, height: Int) -> [[Double]] {
    var polygon_points_array = [[Double]]()
    // Axera 3D segmentation anno do polygon do not have hole anno for now
    // so only one curSeg created.
    var curSeg = [Double]()
    // descpreced for now, order not clear in original annotation
    // for i in stride(from: 0, to: xs.count, by: 1) {
    //     curSeg.append(xs[i])
    //     curSeg.append(ys[i])
    // }

    let scaledDownPoints = scaleDown(
        curFrameImagesItemPoints: axera_inst.points,
        width: width,
        height: height
    )

    let x_points = scaledDownPoints.0
    let y_points = scaledDownPoints.1
    let min_x_points = x_points.min()!
    let max_x_points = x_points.max()!
    let min_y_points = y_points.min()!
    let max_y_points = y_points.max()!
    curSeg.append(min_x_points)
    curSeg.append(min_y_points)
    curSeg.append(max_x_points)
    curSeg.append(min_y_points)
    curSeg.append(max_x_points)
    curSeg.append(max_y_points)
    curSeg.append(min_x_points)
    curSeg.append(max_y_points)

    polygon_points_array.append(curSeg)
    // issue related to cocoapi `https://github.com/cocodataset/cocoapi/issues/139`
    if polygon_points_array[0].count == 4 {
        polygon_points_array[0].append(polygon_points_array[0][0])
        polygon_points_array[0].append(polygon_points_array[0][1])
    }
    return polygon_points_array
}

func calBboxFromCocoSeg(polygon_points_array: [[Double]]) -> [Double] {
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
    return [minX, minY, maxX - minX, maxY - minY]
}

func createDefaultCocoJson() -> CocoAnno {
    var coco_categories = [CocoCategory]()
    let backgoundAnno = CocoCategory(id: 0, name: "background", supercategory: "")
    coco_categories.append(backgoundAnno)

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

func createImageEntry(image_id: Int, file_name: String, height: Int, width: Int, date_captured: String = "", license: Int = 0) -> CocoImage {
    let coco_image = CocoImage(
        id: image_id,
        license: license,
        file_name: file_name,
        height: height,
        width: width,
        date_captured: date_captured
    )
    return coco_image
}

func supercategory2category(supercategory: String, type: String, color: String, typeCN: String) -> String {
    var res = "unknown"
    switch supercategory {
    case "交通灯":
        if type != "unknown", ["red", "yellow", "green", "black"].contains(color) {
            res = "TFL_" + color
        }
    case "路面箭头":
        if type != "unknown" {
            res = "RA_" + type
        }

    case "交通标志":
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
            "pr60"].contains(typeCN)
        {
            res = "TFS_" + typeCN
        } else if typeCN != "unknown" {
            res = "TFS_other"
        }
    case "停止线":
        res = "stop_line"
    case "人行横道":
        res = "crosswalk"
    default:
        res = supercategory
    }
    return res
}
