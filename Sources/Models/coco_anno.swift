struct CocoInfo : Codable {
    var year : String
    var version: String
    var description : String
    var contributor : String
    var url : String
    var date_created : String
}

struct CocoLicense : Codable {
    var url : String
    var id : Int
    var name : String
}

struct CocoCategory : Codable {
    var id : Int
    var name : String
    var supercategory : String
}

struct CocoImage : Codable {
    var id : Int
    var license : Int
    var file_name : String
    var height : Int
    var width : Int
    var date_captured : String
}

struct CocoInstanceAnnotation : Codable {
    var id : Int
    var image_id : Int
    var category_id : Int
    var bbox : [Int]
    var segmentation : [[Int]]
    var area : Int
    var iscrowd : Int
}

struct CocoAnno : Codable {
    var info : CocoInfo
    var licenses : [CocoLicense]
    var categories : [CocoCategory]
    var images : [CocoImage]
    var annotations : [CocoInstanceAnnotation]
}