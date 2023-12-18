// import Foundation
// import PythonKit

// func pytest(frameItem: AxeraFrame.FrameItems,
//             cameraConfig: CameraConfig,
//             FrontCameraMatrix: inout PythonObject,
//             fov_w _: Int,
//             frontCamIntrinsics _: inout PythonObject,
//             np: inout PythonObject,
//             tan: inout PythonObject,
//             pi _: inout PythonObject,
//             yaml _: inout PythonObject) -> [(x: Double, y: Double)]
// {
//     // Calculate projection matrix from intrinsic parameters
//     func projectionMatrix(cameraConfig: CameraConfig, near: Double, far: Double) -> [[Double]] {
//         let aspectRatio = cameraConfig.width / cameraConfig.height
//         // let fov = 2 * atan(cameraConfig.cy / cameraConfig.fy) // Vertical field of view
//         let fov = 2 * atan((cameraConfig.height / 2) / cameraConfig.fy)

//         return matrix_perspective(fov: fov, aspectRatio: aspectRatio, near: near, far: far)
//     }
//     // Utility function to create a perspective projection matrix
//     func matrix_perspective(fov: Double, aspectRatio: Double, near: Double, far: Double) -> [[Double]] {
//         let yScale = Double(1 / tan(fov * 0.5))!
//         let xScale = yScale * aspectRatio
//         let zRange = far - near
//         let zScale = (far + near) / zRange
//         let wzScale = -2 * far * near / zRange

//         return [
//             [xScale, 0, 0, 0],
//             [0, yScale, 0, 0],
//             [0, 0, zScale, 1],
//             [0, 0, wzScale, 0],
//         ]
//     }

//     // Check if a point in world coordinates is within the view frustum
//     func isPointInFrustum(point: [Double], viewMatrix: [[Double]], projectionMatrix: [[Double]]) -> (Bool?, Double?, Double?) {
//         let projectionMatrix_np = np.array(projectionMatrix)
//         let viewMatrix_np = np.array(viewMatrix)
//         let viewProjectionMatrix = np.matmul(projectionMatrix_np, viewMatrix_np)
//         let point_np = np.array(point)
//         let point4 = np.append(point_np, 1.0)
//         let clipSpacePoint = np.matmul(viewProjectionMatrix, point4)

//         // Perform perspective division to convert to NDC
//         let ndc = [
//             clipSpacePoint[0] / clipSpacePoint[3],
//             clipSpacePoint[1] / clipSpacePoint[3],
//             clipSpacePoint[2] / clipSpacePoint[3],
//         ]

//         // Check if the point is within the [-1, 1] range in all dimensions
//         let isInFrustum = abs(ndc[0]) <= 1.0 && abs(ndc[1]) <= 1.0 && abs(ndc[2]) <= 1.0
//         // Map from [-1, 1] to [0, viewport width/height]
//         let x = (Double(ndc[0])! + 1) * 0.5 * Double(cameraConfig.width)
//         let y = (Double(ndc[1])! + 1) * 0.5 * Double(cameraConfig.height)

//         return (isInFrustum, x, y)
//     }

//     // Function to calculate the intersection of a line segment with a plane
//     func intersectionWithPlane(plane: Plane, p0: [Double], p1: [Double]) -> [Double]? {
//         let p0_to_p1 = [p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]]
//         let dotNormalp0_to_p1 = dotProduct(plane.normal, p0_to_p1)
//         if dotNormalp0_to_p1 == 0 { // Line is parallel to the plane, no intersection
//             return nil
//         }
//         let t = (plane.distance - dotProduct(plane.normal, p0)) / dotNormalp0_to_p1
//         if t < 0 || t > 1 { // Intersection point is not within the line segment
//             return nil
//         }
//         // Calculate the intersection point
//         return [p0[0] + t * p0_to_p1[0], p0[1] + t * p0_to_p1[1], p0[2] + t * p0_to_p1[2]]
//     }

//     // Function to check if a point is inside the frustum
//     func isPointInFrustum(point: [Double], frustumPlanes: [Plane]) -> Bool {
//         for plane in frustumPlanes {
//             if dotProduct(plane.normal, point) + plane.distance < 0 {
//                 return false // Point is outside of the frustum
//             }
//         }
//         return true // Point is inside the frustum
//     }

//     func extractFrustumPlanes(viewProjectionMatrix: [[Double]]) -> [Plane] {
//         let vpMatrix = flattenMatrix(viewProjectionMatrix)
//         return [
//             // Left Plane
//             Plane(normal: [
//                 vpMatrix[3] + vpMatrix[0],
//                 vpMatrix[7] + vpMatrix[4],
//                 vpMatrix[11] + vpMatrix[8],
//             ], distance: vpMatrix[15] + vpMatrix[12]),

//             // Right Plane
//             Plane(normal: [
//                 vpMatrix[3] - vpMatrix[0],
//                 vpMatrix[7] - vpMatrix[4],
//                 vpMatrix[11] - vpMatrix[8],
//             ], distance: vpMatrix[15] - vpMatrix[12]),

//             // Bottom Plane
//             Plane(normal: [
//                 vpMatrix[3] + vpMatrix[1],
//                 vpMatrix[7] + vpMatrix[5],
//                 vpMatrix[11] + vpMatrix[9],
//             ], distance: vpMatrix[15] + vpMatrix[13]),

//             // Top Plane
//             Plane(normal: [
//                 vpMatrix[3] - vpMatrix[1],
//                 vpMatrix[7] - vpMatrix[5],
//                 vpMatrix[11] - vpMatrix[9],
//             ], distance: vpMatrix[15] - vpMatrix[13]),
//         ]
//     }

//     // Helper function to flatten a 4x4 matrix into an array
//     func flattenMatrix(_ matrix: [[Double]]) -> [Double] {
//         return Array(matrix.joined())
//     }

//     func dotProduct(_ vec1: [Double], _ vec2: [Double]) -> Double {
//         guard vec1.count == vec2.count else {
//             fatalError("Vectors must be of the same length to calculate dot product")
//         }

//         return zip(vec1, vec2).map(*).reduce(0, +)
//     }
//     // read yaml file
//     let FrontCameraMatrix_np = np.array(FrontCameraMatrix)
//     // x is front axis, y is left axis, z is up axis in world coordinate
//     // x, y, z, l, w, h, yaw in world coordinates
//     var bbox3d_for_cam = [
//         frameItem.position.x,
//         frameItem.position.y,
//         frameItem.position.z,
//         frameItem.dimension.x,
//         frameItem.dimension.y,
//         frameItem.dimension.z,
//         frameItem.rotation2.z,
//     ]

//     // x is front axis, y is left axis, z is up axis
//     let x = bbox3d_for_cam[0]
//     let y = bbox3d_for_cam[1]
//     let z = bbox3d_for_cam[2]
//     let l = bbox3d_for_cam[3]
//     let w = bbox3d_for_cam[4]
//     let h = bbox3d_for_cam[5]
//     // let depth = bbox3d_for_cam[0]
//     // calculate 8 corners
//     let halfLength = l / 2.0
//     let halfWidth = w / 2.0
//     let halfHeight = h / 2.0

//     // Define the eight corners relative to the center
//     let cornersRelativeToCenter_in3D = [
//         (halfLength, halfWidth, halfHeight),
//         (halfLength, -halfWidth, halfHeight),
//         (-halfLength, -halfWidth, halfHeight),
//         (-halfLength, halfWidth, halfHeight),
//         (halfLength, halfWidth, -halfHeight),
//         (halfLength, -halfWidth, -halfHeight),
//         (-halfLength, -halfWidth, -halfHeight),
//         (-halfLength, halfWidth, -halfHeight),
//     ]

//     let point_pairs = [
//         (0, 1), (1, 2), (2, 3),
//         (3, 0), (4, 5), (5, 6),
//         (6, 7), (7, 4), (0, 4),
//         (1, 5), (2, 6), (3, 7),
//     ]

//     var corners3D = [[Double]]()
//     // for corner in rotatedCorners {
//     for corner in cornersRelativeToCenter_in3D {
//         let translatedCorner = [
//             corner.0 + x,
//             corner.1 + y,
//             corner.2 + z,
//         ]
//         corners3D.append(translatedCorner)
//     }
//     // implement frustum culling
//     // Define near and far clipping planes
//     let near = 0.1
//     let far = 1000.0
//     var corners2D = [(x: Double, y: Double)]()
//     // view Matrix
//     var viewMatrix_np = np.array(cameraConfig.tovcs)
//     viewMatrix_np = np.linalg.inv(viewMatrix_np)
//     // Now convert the numpy matrix to your preferred format, for example:
//     var viewMatrix = [[Double]]()
//     for row in viewMatrix_np {
//         viewMatrix.append([Double(row[0])!, Double(row[1])!, Double(row[2])!, Double(row[3])!])
//     }
//     // project Matrix
//     // let projMatrix = projectionMatrix(cameraConfig: cameraConfig)
//     let projMatrix = projectionMatrix(cameraConfig: cameraConfig, near: near, far: far)
//     let projMatrix_np = np.array(projMatrix)
//     let viewProjectionMatrix_np = np.matmul(projMatrix_np, viewMatrix_np)

//     var viewProjectionMatrix = [[Double]]()
//     for row in viewProjectionMatrix_np {
//         viewProjectionMatrix.append([Double(row[0])!, Double(row[1])!, Double(row[2])!, Double(row[3])!])
//     }
//     let planes = extractFrustumPlanes(viewProjectionMatrix: viewProjectionMatrix)

//     // find the intersection of the frustum and the 3D bounding box
//     var intersectionPoints: [[Double]] = []
//     for plane in planes {
//         var point_front: [Double] = []
//         var point_back: [Double] = []

//         for point_pair in point_pairs {
//             point_front = corners3D[point_pair.0]
//             point_back = corners3D[point_pair.1]
//             if let intersection = intersectionWithPlane(plane: plane, p0: point_front, p1: point_back) {
//                 intersectionPoints.append(intersection)
//             }
//         }
//     }
//     // extend corners3D with intersection points
//     let tmp1 = corners3D.count
//     corners3D.append(contentsOf: intersectionPoints)
//     let tmp2 = corners3D.count
//     // if tmp1 != tmp2 {
//     //     print("HHAHAHAHHA")
//     // }
//     // for worldPoint in corners3D {
//     for (_, worldPoint) in corners3D.enumerated() {
//         // Check if the point is within the view frustum
//         let xy2D = isPointInFrustum(point: worldPoint, viewMatrix: viewMatrix, projectionMatrix: projMatrix)
//         if xy2D.0! {
//             corners2D.append((x: xy2D.1!, y: xy2D.2!))
//         }
//     }

//     if corners2D.count <= 1 {
//         return []
//     }
//     return corners2D
// }
