struct Vector3 {
   var x: Double, y: Double, z: Double
}

struct Frustum {
    var vertices = [Vector3]()
}

struct Plane {
    var normal: [Double] // Normal vector of the plane
    var distance: Double // Distance of the plane from the origin along its normal
}

// Define a struct to represent the camera configuration
struct CameraConfig {
    let fx: Double
    let fy: Double
    let cx: Double
    let cy: Double
    let width: Double
    let height: Double
    let tovcs: [[Double]]
}

struct AxeraFrameFrame: Codable {
    var imageUrl: String
    var frameIndex: Int?
    var valid: Bool
    var imageWidth: Int
    var imageHeight: Int
    var rotation: Double
    // deal with dynamic defined attr
    var attributes: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case imageUrl, frameIndex, valid, imageWidth, imageHeight, rotation
        case attributes
    }
}

struct AxeraFrame: Codable {
    struct Position: Codable {
        var x: Double
        var y: Double
        var z: Double
    }

    struct Rotation: Codable {
        var x: Double
        var y: Double
        var z: Double
    }

    struct Dimension: Codable {
        var x: Double
        var y: Double
        var z: Double
    }

    struct Quaternion: Codable {
        var x: Double
        var y: Double
        var z: Double
        var w: Double
    }

    struct PointCount: Codable {
        var lidar: Int
    }

    struct FrameItems: Codable {
        struct LabelsObj: Codable {
            var activity: String
            var visibility: String
            var point_xor_cam: String
        }

        struct Rotation2: Codable {
            var x: Double
            var y: Double
            var z: Double
        }

        var type: String
        var position: Position
        var rotation: Rotation
        var dimension: Dimension
        var quaternion: Quaternion

        var category: String
        var id: String
        var number: Int?
        var interpolated: Bool
        var frameNum: Int
        var pointCount: PointCount
        var labels: String?
        var isEmpty: Bool?
        var annotatedBy: String?
        var reviewKey: String?
        var labelsObj: LabelsObj?
        var rotation2: Rotation2
        var item_id: Int?

        // deal with `labels` sometiems is String sometimes is `null` in json
        private enum CodingKeys: String, CodingKey {
            case type, position, rotation, dimension,
                 quaternion, category, id, number,
                 interpolated, frameNum, pointCount, labels,
                 isEmpty, annotatedBy, reviewKey,
                 rotation2,item_id,labelsObj
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            type = try container.decode(String.self, forKey: .type)
            position = try container.decode(Position.self, forKey: .position)
            rotation = try container.decode(Rotation.self, forKey: .rotation)
            dimension = try container.decode(Dimension.self, forKey: .dimension)
            quaternion = try container.decode(Quaternion.self, forKey: .quaternion)
            category = try container.decode(String.self, forKey: .category)
            id = try container.decode(String.self, forKey: .id)
            interpolated = try container.decode(Bool.self, forKey: .interpolated)
            frameNum = try container.decode(Int.self, forKey: .frameNum)
            pointCount = try container.decode(PointCount.self, forKey: .pointCount)
            rotation2 = try container.decode(Rotation2.self, forKey: .rotation2)

            if let numberContainer = try? container.decode(Int.self, forKey: .number) {
                number = numberContainer
            } else {
                number = 0
            }

            if let labelsObjContainer = try? container.decode(LabelsObj.self, forKey: .labelsObj) {
                labelsObj = labelsObjContainer
            } else {
                labelsObj = nil
            }

            if let labelsContainer = try? container.decode(String.self, forKey: .labels) {
                labels = labelsContainer
            } else {
                labels = nil
            }

            if let item_idContainer = try? container.decode(Int.self, forKey: .item_id) {
                item_id = item_idContainer
            } else {
                item_id = nil
            }

            if let reviewKeyContainer = try? container.decode(String.self, forKey: .reviewKey) {
                reviewKey = reviewKeyContainer
            } else {
                reviewKey = nil
            }

            if let annotatedByContainer = try? container.decode(String.self, forKey: .annotatedBy) {
                annotatedBy = annotatedByContainer
            } else {
                annotatedBy = nil
            }

            if let isEmptyContainer = try? container.decode(Bool.self, forKey: .isEmpty) {
                isEmpty = isEmptyContainer
            } else {
                isEmpty = nil
            }
        }
    }

    struct FrameImages: Codable {
        struct CameraCubes: Codable {
            // Annotion in axera formamt has this filed but not filled yet
        }

        struct CameraCubesCasts: Codable {
            // Annotion in axera formamt has this filed but not filled yet
        }

        struct FrameImagesAttribute: Codable {
            // Annotion in axera formamt has this filed but not filled yet
        }

        struct FrameImagesItem: Codable {
            struct FrameImagesItemPosition: Codable {
                var x: Double
                var y: Double
            }

            struct FrameImagesItemRotation: Codable {
                var x: Double
                var y: Double
            }

            struct FrameImagesItemLabels: Codable {
                // Annotion in axera formamt has this filed but not filled yet
            }

            struct FrameImagesItemPoints: Codable {
                var x: [Double]
                var y: [Double]
            }

            struct FrameImagesItemInvisibleIndex: Codable {
                // Annotion in axera formamt has this filed but not filled yet
            }

            struct FrameImagesItemLabelsObj: Codable {
                // Annotion in axera formamt has this filed but not filled yet
            }

            var type: String
            var id: String
            var number: Double
            var category: String
            var frameNum: Int
            var imageNum: Int

            var position: FrameImagesItemPosition
            var dimension: FrameImagesItemRotation
            var labels: FrameImagesItemLabels? // TODO: null in json
            var isManual: Bool
            var points: FrameImagesItemPoints
            var invisibleIndex: FrameImagesItemInvisibleIndex
            var reviewKey: String
            var labelsObj: FrameImagesItemLabelsObj? // TODO: null in json
        }

        var image: String
        var imageUrlInternal: String
        var imageUrlExternal: String
        var width: Int
        var height: Int
        var items: [FrameImagesItem]
        var cameraCubes: [CameraCubes]
        var cameraCubeCasts: [CameraCubesCasts]
        var attribute: FrameImagesAttribute?
    }

    struct Instance3DAttributes: Codable {
        // Annotion in axera formamt has this filed but not filled yet
    }

    struct relations: Codable {
        // Annotion in axera formamt has this filed but not filled yet
    }

    struct boundary: Codable {
        // Annotion in axera formamt has this filed but not filled yet
    }

    var camera: String? // 2D axera anno exclusively
    var frames: [AxeraFrameFrame]? // 2D axera anno exclusively
    var frameId: Int? // 3D axera anno exclusively
    var frameUrl: String? // 3D axera anno exclusively
    var frameUrlInternal: String? // 3D axera anno exclusively
    var frameUrlExternal: String? // 3D axera anno exclusively
    var items: [FrameItems]? // 3D axera anno exclusively
    var images: [FrameImages]? // 3D axera anno exclusively
    var attribute: String? // 3D axera anno exclusively
    var instanceAttributes: [Instance3DAttributes]? // 3D axera anno exclusively
    var relations: [relations]? // 3D axera anno exclusively
    var isValid: Bool? // 3D axera anno exclusively
    var groundY: Double? // 3D axera anno exclusively
    var boundary: boundary? // 3D axera anno exclusively
}

struct AxeraCameraFrame: Codable {
    var frameIndex: Int?
    var isKeyFrame: Bool?
    var shapeType: String?
    var shape: BaseShape?
    var order: Int?
    var attributes: [String: String]?
    var isOCR: Bool?
    var isFormula: Bool?
    var OCRText: String?

    private enum CodingKeys: String, CodingKey {
        case shapeType
        case shape
        case attributes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        shapeType = try container.decode(String.self, forKey: .shapeType)

        // print the type of BaseShape

        switch shapeType {
        // TODO:
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

        // important
        if let attributesContainer = try? container.decode([String: String].self, forKey: .attributes) {
            attributes = attributesContainer
        } else if let emptyString = try? container.decodeIfPresent(String.self, forKey: .attributes), emptyString == "" {
            attributes = nil
        } else {
            attributes = nil
        }
    }
}

struct AxeraCamera: Codable {
    var camera: String
    var frames: [AxeraCameraFrame]
}

struct AxeraChild: Codable {
    var id: String
    var name: String
    var displayName: String
    var displayColor: String
    var number: Int
    var cameras: [AxeraCamera]
}

struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue _: Int) {
        return nil
    }
}

struct AxeraInstance: Codable {
    var id: String
    var category: String
    var categoryName: String
    var number: Int
    var children: [AxeraChild]
    // deal with `attributes` sometimes is "", sometimes is a [string:string] pair
    var attributes: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case id, category, categoryName, number, children, attributes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        category = try container.decode(String.self, forKey: .category)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        number = try container.decode(Int.self, forKey: .number)
        children = try container.decode([AxeraChild].self, forKey: .children)

        if let attributesContainer = try? container.decode([String: String].self, forKey: .attributes) {
            attributes = attributesContainer
        } else if let emptyString = try? container.decodeIfPresent(String.self, forKey: .attributes), emptyString == "" {
            attributes = nil
        } else {
            attributes = nil
        }
    }
}

// defines axera shapes

struct AxeraImageAnno: Codable {
    var baseUrl: String? // 3D axera anno exclusively
    var auditId: String
    var instances: [AxeraInstance]?
    var frames: [AxeraFrame]
    var relationships: [[String: String]]?
    var attributes: [String: String]?
    var statistics: String
}
