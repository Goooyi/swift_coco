enum BaseShape: Codable {
    case rectangle(Rectangle)
    case polygon(Polygon)
    case line(Line)
    case ellipse(Ellipse)
    case dot(Dot)
    case cuboid(Cuboid)
    case l_shape(L_shape)
    case grid(Grid)
}

struct Rectangle_points: Codable {
    var x: Double
    var y: Double
}

struct Rectangle: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var area: Double
    var rotation: Double
    var points: [Rectangle_points]
    var center: Double?
}

struct UserData: Codable {
    var start: Bool?
    var end: Bool?
}

struct Polygon_points: Codable {
    var x: Double
    var y: Double
    var userData: UserData?
}

struct Polygon: Codable {
    var points: [Polygon_points]
}

struct Line: Codable {
    var points: [Polygon_points]
}

struct Ellipse: Codable {
    var x: Double
    var y: Double
    var halfWidth: Double
    var halfHeight: Double
}

struct Dot: Codable {
    var x: Double
    var y: Double
}

struct CuboidFrontBack: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

struct Cuboid: Codable {
    var front: CuboidFrontBack
    var back: CuboidFrontBack
}

struct L_shape: Codable {
    var front: CuboidFrontBack
    var sidePoints: [Rectangle_points]
    var center: Double
}

struct Grid: Codable {
    var cols: [[String: Double]]
    var rows: [[String: Double]]
}
