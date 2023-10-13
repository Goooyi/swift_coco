struct coco_info : Codable {
    var year : String
    var version: String
    var description : String
    var contributor : String
    var url : String
    var date_created : String
}

struct coco_license : Codable {
    var url : String
    var id : Int
    var name : String
}

struct coco_category : Codable {
    var id : Int
    var name : String
    var supercategory : String
}

struct coco_image : Codable {
    var id : Int
    var license : Int
    var file_name : String
    var height : Int
    var width : Int
    var date_captured : String
}

struct coco_annotation : Codable {
    var id : Int
    var image_id : Int
    var category_id : Int
    var bbox : [Int]
    var segmentation : [[Int]]
    var area : Int
    var iscrowd : Int
}

struct coco_anno : Codable {
    var info : coco_info
    var licenses : [coco_license]
    var categories : [coco_category]
    var images : [coco_image]
    var annotations : [coco_annotation]
}