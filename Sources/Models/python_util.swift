import Foundation
import PythonKit

func pytest(frameItem: AxeraFrame.FrameItems,
            FrontCameraMatrix: PythonObject,
            fov_w: Int,
            frontCamIntrinsics: PythonObject)
{
    let sys = Python.import("sys")
    // print("Python Path \(sys.path)")
    // print("Python \(sys.version_info.major).\(sys.version_info.minor)")
    // print("Python Version: \(sys.version)")
    // print("Python Encoding: \(sys.getdefaultencoding().upper())")
    let np = Python.import("numpy")
    let torch = Python.import("torch")
    let Tensor = torch.Tensor
    let cv2 = Python.import("cv2")
    let Rotation = Python.import("scipy.spatial.transform").Rotation
    let Quaternion = Python.import("pyquaternion.quaternion").Quaternion
    let tan = Python.import("math").tan
    let pi = Python.import("math").pi
    let yaml = Python.import("yaml")
    let Path = Python.import("pathlib").Path

    // read yaml file
    let FrontCameraMatrix_np = np.array(FrontCameraMatrix)
    // x, y, z, l, w, h, yaw
    var bbox3d_for_cam = [
        frameItem.position.x,
        frameItem.position.y,
        frameItem.position.z,
        frameItem.dimension.x,
        frameItem.dimension.y,
        frameItem.dimension.z,
        frameItem.rotation2.z,
    ]
    let sensor2ego_rotation = FrontCameraMatrix_np[..<3, ..<3]
    let sensor2ego_translation = FrontCameraMatrix_np[..<3, 3]
    let cam_coord = np.dot(
        np.linalg.inv(np.array(sensor2ego_rotation)),
        np.array(bbox3d_for_cam)[..<3] - np.array(sensor2ego_translation)
    )
    for i in 0 ..< 3 {
        bbox3d_for_cam[i] = Double(cam_coord[i])!
    }

    // yaw to [-pi, pi]
    let nppi = Double(np.pi)!
    var yaw = bbox3d_for_cam[6]
    yaw = nppi * 1.5 - yaw
    if yaw > nppi {
        while yaw > nppi {
            yaw -= 2 * nppi
        }
    } else if yaw < -nppi {
        while yaw < -nppi {
            yaw += 2 * nppi
        }
    }
    assert(yaw > -nppi - 1e-4 && yaw < nppi + 1e-4, "yaw: \(yaw)")

    let x = bbox3d_for_cam[0]
    let y = bbox3d_for_cam[1]
    let z = bbox3d_for_cam[2]
    let l = bbox3d_for_cam[3]
    let w = bbox3d_for_cam[4]
    let h = bbox3d_for_cam[5]
    let depth = bbox3d_for_cam[0]
    // calculate 8 corners
    let halfLength = l / 2.0
    let halfWidth = w / 2.0
    let halfHeight = h / 2.0

    // Define the eight corners relative to the center
    let cornersRelativeToCenter = [
        (halfLength, halfWidth, halfHeight),
        (halfLength, -halfWidth, halfHeight),
        (-halfLength, -halfWidth, halfHeight),
        (-halfLength, halfWidth, halfHeight),
        (halfLength, halfWidth, -halfHeight),
        (halfLength, -halfWidth, -halfHeight),
        (-halfLength, -halfWidth, -halfHeight),
        (-halfLength, halfWidth, -halfHeight),
    ]

    // Translate corners to the actual position using the center coordinates
    // var corners = [(Double, Double, Double)]()
    var corners: [(x: Double, y: Double, z: Double)] = []
    for corner in cornersRelativeToCenter {
        let translatedCorner = (
            x: corner.0 + x,
            y: corner.1 + y,
            z: corner.2 + z
        )
        corners.append(translatedCorner)
    }

    // clip
    let clipDepth = abs(depth) / Double(tan(Double(fov_w) / 2.0 / 180.0 * Double(pi)!))! // Replace with your actual clip depth

    // Check if any corner's x is greater than the clip depth
    let shouldClip = corners.contains { $0.x > clipDepth }

    if shouldClip {
        // At least one corner has x greater than clip depth, so update all corners
        for i in 0 ..< corners.count {
            corners[i].x = max(clipDepth, corners[i].x)
        }
    } else {
        return
    }
    // Camera intrinsic parameters
    let fx = Double(frontCamIntrinsics["fx"])!
    let fy = Double(frontCamIntrinsics["fy"])!
    let cx = Double(frontCamIntrinsics["cx"])!
    let cy = Double(frontCamIntrinsics["cy"])!

    // Assuming 'corners' is already clipped and contains 3D points in camera coordinates
    var corners2D = [(x: Double, y: Double)]()

    for corner in corners {
        // Apply the perspective projection formula
        let x2D = (fx * corner.x) / corner.z + cx
        let y2D = (fy * corner.y) / corner.z + cy

        // Append the projected 2D point to the corners2D array
        corners2D.append((x: x2D, y: y2D))
    }

    print(corners2D)

    // 'corners2D' now contains the 2D coordinates on the camera image plane
}
