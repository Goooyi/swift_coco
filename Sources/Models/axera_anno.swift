struct axera_frame_frame: Codable {
    var imageUrl: String
    var frameIndex: Int?
    var valid: Bool
    var imageWidth: Int
    var imageHeight: Int
    var rotation: Double
    // deal with dynamic defined attr
    var attributes: [String: String]?

    enum CodingKeys: String, CodingKey {
        case imageUrl, frameIndex, valid, imageWidth, imageHeight, rotation
        case attributes
    }
}

struct axera_frame: Codable {
    var camera: String
    var frames: [axera_frame_frame]
}

struct axera_camera_frame: Codable {
    var frameIndex: Int?
    var isKeyFrame: Bool?
    var shapeType: String?
    // TODO: enum to deal with different shape
    var shape: BaseShape?
    var order: Int?
    var attributes: [String: String]?
    var isOCR: Bool?
    var isFormula: Bool?
    var OCRText: String?

    enum CodingKeys: String, CodingKey {
        case shapeType
        case shape
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        shapeType = try container.decode(String.self, forKey: .shapeType)

        //print the type of BaseShape

        switch shapeType {
        // TODO
        case "rectangle":
            let rect = try container.decode(Rectangle.self, forKey: .shape)
            shape = .rectangle(rect)
        case "polygon":
            let poly = try container.decode(Polygon.self, forKey: .shape)
            shape = .polygon(poly)
        case "line":
            let line = try container.decode(Line.self, forKey: .shape)
            shape = .line(line)
        case "ellipse":
            let elli = try container.decode(Ellipse.self, forKey: .shape)
            shape = .ellipse(elli)
        case "dot":
            let dot = try container.decode(Dot.self, forKey: .shape)
            shape = .dot(dot)
        case "cuboid":
            let cub = try container.decode(Cuboid.self, forKey: .shape)
            shape = .cuboid(cub)
        case "l_shape":
            let l_shape = try container.decode(L_shape.self, forKey: .shape)
            shape = .l_shape(l_shape)
        case "grid":
            let grid = try container.decode(Grid.self, forKey: .shape)
            shape = .grid(grid)
        default:
            shape = nil
        }
    }
}

struct axera_camera: Codable {
    var camera: String
    var frames: [axera_camera_frame]
}

struct axera_child: Codable {
    var id: String
    var name: String
    var displayName: String
    var displayColor: String
    var number: Int
    var cameras: [axera_camera]
}

struct axera_instance: Codable {
    var id: String
    var category: String
    var categoryName: String
    var number: Int
    var attributes: [String: String]?
    var children: [axera_child]
}

// defines axera shapes

struct axera_img_anno: Codable {
    var auditId: String
    var instances: [axera_instance]
    var frames: [axera_frame]
    var relationships: [[String: String]]
    var attributes: [String: String]?
    var statistics: String
}
