protocol axera_shape {
    var shapeType : String { get }
}

struct axera_rect : Codable {
    var x : Int
    var y : Int
    var width : Int
    var height : Int
    var rotation : Int
    var points : [[String: Any]]
}

struct axera_frame_frame : Codable {
    var frameIndex : Int
    var valid : Bool
    // TODO variable length attributes
}

struct axera_frame : Codable {
    var camera : String
    var frames : [axera_frame_frame]
}
struct axera_camera_frame : Codable {
    var frameIndex : Int
    var isKeyFrame : Bool
    var shapeType : String
    // TODO : generic to deal with different shape
    var shape : axera_shape
    var order : Int
    var attributes : [String: Any]
    var isOCR : Bool
    var OCRText : String
}

struct axera_camera : Codable {
    var camera : String
    var frames : [axera_camera_frame]
}

struct axera_child : Codable {
    var id : String
    var name : String
    var number : Int
    var cameras : [axera_camera]
}

struct axera_instance : Codable {
    var id : String
    var category : String
    var number : Int
    var attributes : [String: Any]
    var children : [axera_child]
}

// defines axera shapes

struct axera_img_anno : Codable {
    var auditId : String
    var instances : [axera_instance]
    var frames : [axera_frame]
    var statistics : String
}