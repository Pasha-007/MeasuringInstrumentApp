import SwiftUI
import ARKit
import SceneKit

struct ARObjectSizeView: UIViewControllerRepresentable {
    @Binding var measuredSize: String

    func makeUIViewController(context: Context) -> ARObjectSizeViewController {
        let arVC = ARObjectSizeViewController()
        arVC.measuredSize = $measuredSize
        return arVC
    }

    func updateUIViewController(_ uiViewController: ARObjectSizeViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: ARObjectSizeViewController, coordinator: ()) {
        uiViewController.pauseSession()
    }
}

class ARObjectSizeViewController: UIViewController, ARSCNViewDelegate {
    var arView: ARSCNView!
    var measuredSize: Binding<String>?
    var startPoint: SCNVector3?
    var endPoint: SCNVector3?

    override func viewDidLoad() {
        super.viewDidLoad()

        arView = ARSCNView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.delegate = self
        view.addSubview(arView)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        print("✅ ARKit session started for Object Measurement")
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let touchLocation = gesture.location(in: arView)
        let hitResults = arView.hitTest(touchLocation, types: .featurePoint)

        guard let result = hitResults.first else { return }
        let worldTransform = result.worldTransform
        let position = SCNVector3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)

        if startPoint == nil {
            startPoint = position
            placeSphere(at: position, color: .green) // Green for start
            print("🟢 First Point Selected: \(position)")
        } else if endPoint == nil {
            endPoint = position
            placeSphere(at: position, color: .red) // Red for end
            print("🔴 Second Point Selected: \(position)")
            measureDistance()
        } else {
            resetMeasurement()
        }
    }

    func add3DLabel(for text: String, at start: SCNVector3, to end: SCNVector3) {
        let midpoint = midpointBetween(start, end)

        // Create a 3D text geometry
        let textGeometry = SCNText(string: text, extrusionDepth: 1)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.font = UIFont.systemFont(ofSize: 12, weight: .bold)

        // Create a text node
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = midpoint

        // Scale down the text so it fits AR scene
        textNode.scale = SCNVector3(0.005, 0.005, 0.005)

        // Make text always face the user
        textNode.constraints = [SCNBillboardConstraint()]

        // Add to AR scene
        arView.scene.rootNode.addChildNode(textNode)
    }
    
    func measureDistance() {
        guard let start = startPoint, let end = endPoint else { return }

        let distance = sqrt(
            pow(end.x - start.x, 2) +
            pow(end.y - start.y, 2) +
            pow(end.z - start.z, 2)
        )

        let distanceInCm = distance * 100 // Convert meters to cm
        let distanceText = String(format: "%.2f cm", distanceInCm)

        measuredSize?.wrappedValue = "Measured Size: \(distanceText)"
        print("📏 Measured Distance: \(distanceText)")

        drawThickLine(from: start, to: end, distanceText: distanceText) // ✅ Corrected
//        add3DLabel(for: distanceText, at: start, to: end) // ✅ Passes the text correctly
    }
    

    func drawThickLine(from start: SCNVector3, to end: SCNVector3, distanceText: String) {
        let cylinder = SCNCylinder(radius: 0.002, height: CGFloat(distanceBetween(start, end)))
        cylinder.firstMaterial?.diffuse.contents = UIColor.blue
        
        let lineNode = SCNNode(geometry: cylinder)
        lineNode.position = midpointBetween(start, end)
        lineNode.look(at: SCNVector3(end.x, end.y, end.z), up: arView.scene.rootNode.worldUp, localFront: lineNode.worldUp)

        // ✅ Create an ARAnchor at the midpoint
        let anchor = ARAnchor(name: "measurementLine", transform: simd_float4x4(lineNode.worldTransform))
        arView.session.add(anchor: anchor)

        // ✅ Attach the line to an anchor node
        let anchorNode = SCNNode()
        anchorNode.addChildNode(lineNode)
        
        // ✅ Create and attach the measurement label
        let textNode = createTextNode(text: distanceText, position: lineNode.position)
        anchorNode.addChildNode(textNode)

        arView.scene.rootNode.addChildNode(anchorNode)
    }
    
    func createTextNode(text: String, position: SCNVector3) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.font = UIFont.systemFont(ofSize: 8, weight: .bold)

        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.001, 0.001, 0.001) // Scale down text
        textNode.position = SCNVector3(position.x, position.y + 0.01, position.z) // Raise text slightly above line
        
        return textNode
    }

    func placeSphere(at position: SCNVector3, color: UIColor) {
        let sphere = SCNSphere(radius: 0.005) // Small sphere
        sphere.firstMaterial?.diffuse.contents = color

        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        arView.scene.rootNode.addChildNode(sphereNode)
    }

    func resetMeasurement() {
        startPoint = nil
        endPoint = nil
        measuredSize?.wrappedValue = "Tap two points to measure"

        print("🔄 Ready for new measurement (Old lines remain)")
    }

    func pauseSession() {
        arView.session.pause()
    }

    deinit {
        pauseSession()
    }

    private func distanceBetween(_ start: SCNVector3, _ end: SCNVector3) -> Float {
        return sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2) + pow(end.z - start.z, 2))
    }

    func midpointBetween(_ start: SCNVector3, _ end: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
    }
}
