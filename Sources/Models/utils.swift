import Foundation
// TODO: pass by reference?
func axeraImgAnno2cocoAnno(axera_img_anno _: AxeraImageAnno, coco_anno _: CocoAnno) {}

func createDefaultCocoJson(datasetConfigURL: URL) -> CocoAnno {
    var coco_categories = [CocoCategory]()
    // parse category
    let fileContents = try! String(contentsOf: datasetConfigURL)
    let lines = fileContents.components(separatedBy: "\n")
    for line in lines {
        let parts = line.split(separator: " ")
        let id = Int(parts[0])!
        let name = String(parts[1])

        let category = CocoCategory(id: id, name: name, supercategory:"")
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
        id: 1,
        name: ""
    )

    var coco_anno = CocoAnno(
        info: coco_info,
        licenses: [coco_license],
        categories: coco_categories,
        images: [],
        annotations: []
    )
    return coco_anno
}
