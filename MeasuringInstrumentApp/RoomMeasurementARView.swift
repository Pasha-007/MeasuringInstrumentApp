//
//  RoomMeasurementARView.swift
//  MeasuringInstrumentApp
//

import SwiftUI
import ARKit
import SceneKit

struct RoomMeasurementARView: UIViewControllerRepresentable {
    @Binding var measuredHeight: String
    @Binding var floorArea: String
    @Binding var ceilingArea: String
    @Binding var measurementStatus: String
    @Binding var measurementAccuracy: Double
    @Binding var currentMode: FloorCeilingView.MeasurementMode
    @Binding var isLoading: Bool

    func makeUIViewController(context: Context) -> RoomMeasurementViewController {
        let arVC = RoomMeasurementViewController()
        arVC.measuredHeight = $measuredHeight
        arVC.floorArea = $floorArea
        arVC.ceilingArea = $ceilingArea
        arVC.measurementStatus = $measurementStatus
        arVC.measurementAccuracy = $measurementAccuracy
        arVC.currentMode = $currentMode
        arVC.isLoading = $isLoading
        return arVC
    }

    func updateUIViewController(_ uiViewController: RoomMeasurementViewController, context: Context) {
        // Update controller when bindings change
        uiViewController.updateMode()
    }

    static func dismantleUIViewController(_ uiViewController: RoomMeasurementViewController, coordinator: ()) {
        uiViewController.pauseSession()
    }
}

class RoomMeasurementViewController: UIViewController, ARSCNViewDelegate {
    // MARK: - Properties
    
    // AR View
    var arView: ARSCNView!
    
    // Binding properties
    var measuredHeight: Binding<String>?
    var floorArea: Binding<String>?
    var ceilingArea: Binding<String>?
    var measurementStatus: Binding<String>?
    var measurementAccuracy: Binding<Double>?
    var currentMode: Binding<FloorCeilingView.MeasurementMode>?
    var isLoading: Binding<Bool>?
    
    // Plane detection
    private var floorNode: SCNNode?
    private var floorAnchor: ARPlaneAnchor?
    private var floorDetected = false
    
    // Corner markers
    private var floorCorners: [SCNVector3] = []
    private var ceilingCorners: [SCNVector3] = []
    private var floorMarkers: [SCNNode] = []
    private var ceilingMarkers: [SCNNode] = []
    
    // Height measurement
    private var floorHeight: Float?
    private var ceilingHeight: Float?
    private var heightMeasurementPoints: [SCNVector3] = []
    
    // Polygon visualization
    private var floorPolygonNode: SCNNode?
    private var ceilingPolygonNode: SCNNode?
    
    // Status indicators
    private var instructionNode: SCNNode?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupGestureRecognizers()
    }
    
    func updateMode() {
        // This gets called when bindings change from SwiftUI
        // Use it to react to mode changes initiated from the UI
    }
    
    // MARK: - Setup Methods
    
    private func setupARView() {
        arView = ARSCNView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.delegate = self
        view.addSubview(arView)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        // Run session with provided configuration
        arView.session.run(configuration)
        
        // Show feature points to help with detection
        arView.debugOptions = [.showFeaturePoints]
        
        // Set initial status
        DispatchQueue.main.async {
            self.measurementStatus?.wrappedValue = "Move camera to detect floor"
        }
    }
    
    private func setupGestureRecognizers() {
        // Add tap gesture for marking points
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Tap Gesture Handler
    
    @objc private func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let currentMode = currentMode?.wrappedValue else { return }
        
        let touchLocation = gestureRecognizer.location(in: arView)
        
        switch currentMode {
        case .detectFloor:
            // In detect floor mode, taps do nothing - just wait for plane detection
            return
            
        case .markFloorCorners:
            // Add floor corner
            addFloorCorner(at: touchLocation)
            
        case .measureHeight:
            // Measure height by tapping on ceiling
            measureCeilingHeight(at: touchLocation)
            
        case .markCeilingCorners:
            // Add ceiling corner
            addCeilingCorner(at: touchLocation)
            
        case .complete:
            // In complete mode, taps do nothing
            return
        }
    }
    
    // MARK: - Plane Detection
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Only process plane anchors
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Only process horizontal planes when in detect floor mode
        if currentMode?.wrappedValue == .detectFloor {
            // Check if the plane is horizontal (floor)
            let planeNormal = simd_make_float3(planeAnchor.transform.columns.1)
            
            // Floor planes have normals pointing up (y ≈ 1)
            if planeNormal.y > 0.8 && !floorDetected {
                print("✅ Floor plane detected")
                floorAnchor = planeAnchor
                floorNode = node
                floorDetected = true
                
                // Save the floor height
                floorHeight = planeAnchor.transform.columns.3.y
                
                // Add floor visualization
                addFloorVisualization(to: node, for: planeAnchor)
                
                // Update UI
                DispatchQueue.main.async {
                    self.measurementStatus?.wrappedValue = "Floor detected! Tap Next to mark corners"
                    self.isLoading?.wrappedValue = false
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // If this is our floor plane, update it
        if floorAnchor?.identifier == planeAnchor.identifier {
            floorAnchor = planeAnchor
            updateFloorVisualization(node: node, anchor: planeAnchor)
        }
    }
    
    // MARK: - Floor Visualization
    
    private func addFloorVisualization(to node: SCNNode, for planeAnchor: ARPlaneAnchor) {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // Make it semi-transparent green
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
        plane.materials = [material]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0) // Rotate to be horizontal
        
        node.addChildNode(planeNode)
    }
    
    private func updateFloorVisualization(node: SCNNode, anchor: ARPlaneAnchor) {
        guard let planeNode = node.childNodes.first,
              let plane = planeNode.geometry as? SCNPlane else {
            return
        }
        
        // Update plane size
        plane.width = CGFloat(anchor.extent.x)
        plane.height = CGFloat(anchor.extent.z)
        
        // Update position
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    }
    
    // MARK: - Corner Marking Methods
    
    private func addFloorCorner(at touchLocation: CGPoint) {
        // Perform hit test against existing planes
        let hitResults = arView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        guard let result = hitResults.first else {
            // If no plane is hit, show a message
            DispatchQueue.main.async {
                self.measurementStatus?.wrappedValue = "Cannot place point. Make sure to tap on the detected floor."
            }
            return
        }
        
        // Get the hit position
        let hitPosition = SCNVector3(
            result.worldTransform.columns.3.x,
            result.worldTransform.columns.3.y,
            result.worldTransform.columns.3.z
        )
        
        // Add to floor corners
        floorCorners.append(hitPosition)
        
        // Add visual marker
        let markerNode = createMarkerNode(color: .green)
        markerNode.position = hitPosition
        arView.scene.rootNode.addChildNode(markerNode)
        floorMarkers.append(markerNode)
        
        // Connect corners with lines if we have more than one
        if floorCorners.count > 1 {
            let fromPoint = floorCorners[floorCorners.count - 2]
            let toPoint = floorCorners[floorCorners.count - 1]
            addLine(from: fromPoint, to: toPoint, color: .green)
        }
        
        // If we have 3 or more corners, update the polygon and calculate area
        if floorCorners.count >= 3 {
            updateFloorPolygon()
            calculateFloorArea()
        }
        
        // If this is 4th point, close the polygon
        if floorCorners.count >= 4 {
            // Connect last point to first point
            addLine(from: floorCorners.last!, to: floorCorners.first!, color: .green)
            
            // Suggest moving to next stage
            DispatchQueue.main.async {
                self.measurementStatus?.wrappedValue = "Floor marked with \(self.floorCorners.count) corners. Tap Next to measure height."
            }
        } else {
            // Update count
            DispatchQueue.main.async {
                self.measurementStatus?.wrappedValue = "Added corner \(self.floorCorners.count). Add at least 3-4 corners."
            }
        }
    }
    
    private func measureCeilingHeight(at touchLocation: CGPoint) {
        // For ceiling height, we use feature points since ceiling might not be detected as a plane
        let hitResults = arView.hitTest(touchLocation, types: .featurePoint)
        
        guard let result = hitResults.first else {
            DispatchQueue.main.async {
                self.measurementStatus?.wrappedValue = "No feature points detected. Try again."
            }
            return
        }
        
        // Get the hit position
        let hitPosition = SCNVector3(
            result.worldTransform.columns.3.x,
            result.worldTransform.columns.3.y,
            result.worldTransform.columns.3.z
        )
        
        // Save this as a ceiling point
        heightMeasurementPoints.append(hitPosition)
        
        // Add visual marker
        let markerNode = createMarkerNode(color: .blue)
        markerNode.position = hitPosition
        arView.scene.rootNode.addChildNode(markerNode)
        
        // For visualization, add a vertical line from floor to this point
        if let floorPos = floorCorners.first {
            // Create a point directly below the ceiling point at floor height
            let floorPoint = SCNVector3(hitPosition.x, floorPos.y, hitPosition.z)
            addLine(from: floorPoint, to: hitPosition, color: .yellow)
            
            // Calculate height
            let height = hitPosition.y - floorPos.y
            
            // Update ceiling height
            ceilingHeight = height
            
            // Calculate and show the height
            calculateAndDisplayHeight()
            
            DispatchQueue.main.async {
                self.measurementStatus?.wrappedValue = "Height measured. Tap Next to mark ceiling corners."
            }
        }
    }
    
    private func addCeilingCorner(at touchLocation: CGPoint) {
        // For ceiling corners, we use feature points
        let hitResults = arView.hitTest(touchLocation, types: .featurePoint)
        
        guard let result = hitResults.first else {
            DispatchQueue.main.async {
                self.measurementStatus?.wrappedValue = "No feature points detected. Try again."
            }
            return
        }
        
        // Get the hit position
        let hitPosition = SCNVector3(
            result.worldTransform.columns.3.x,
            result.worldTransform.columns.3.y,
            result.worldTransform.columns.3.z
        )
        
        // Add to ceiling corners
        ceilingCorners.append(hitPosition)
        
        // Add visual marker
        let markerNode = createMarkerNode(color: .blue)
        markerNode.position = hitPosition
        arView.scene.rootNode.addChildNode(markerNode)
        ceilingMarkers.append(markerNode)
        
        // Connect corners with lines if we have more than one
        if ceilingCorners.count > 1 {
            let fromPoint = ceilingCorners[ceilingCorners.count - 2]
            let toPoint = ceilingCorners[ceilingCorners.count - 1]
            addLine(from: fromPoint, to: toPoint, color: .blue)
        }
        
        // If we have 3 or more corners, update the polygon and calculate area
        if ceilingCorners.count >= 3 {
            updateCeilingPolygon()
            calculateCeilingArea()
        }
        
        // If we have same number of ceiling corners as floor corners, close the polygon
        if ceilingCorners.count >= floorCorners.count || ceilingCorners.count >= 4 {
            // Connect last point to first point
            addLine(from: ceilingCorners.last!, to: ceilingCorners.first!, color: .blue)
            
            // Also connect ceiling corners to floor corners with vertical lines
            for i in 0..<min(floorCorners.count, ceilingCorners.count) {
                addLine(from: floorCorners[i], to: ceilingCorners[i], color: .yellow.withAlphaComponent(0.3))
            }
            
            DispatchQueue.main.async {
                self.measurementStatus?.wrappedValue = "Ceiling marked with \(self.ceilingCorners.count) corners. Tap Next to finish."
                
                // Move to complete mode
                self.currentMode?.wrappedValue = .complete
            }
        } else {
            // Update count
            DispatchQueue.main.async {
                self.measurementStatus?.wrappedValue = "Added ceiling corner \(self.ceilingCorners.count). Add \(self.floorCorners.count) corners total."
            }
        }
    }
    
    // MARK: - Measurement Calculations
    
    private func calculateFloorArea() {
        guard floorCorners.count >= 3 else { return }
        
        // Calculate area of the polygon
        let area = calculatePolygonArea(floorCorners)
        
        // Update UI with the area
        DispatchQueue.main.async {
            let areaInSquareMeters = area
            let areaInSquareFeet = areaInSquareMeters * 10.764
            
            self.floorArea?.wrappedValue = String(format: "%.2f m² (%.2f sq ft)", areaInSquareMeters, areaInSquareFeet)
        }
    }
    
    private func calculateCeilingArea() {
        guard ceilingCorners.count >= 3 else { return }
        
        // Calculate area of the polygon
        let area = calculatePolygonArea(ceilingCorners)
        
        // Update UI with the area
        DispatchQueue.main.async {
            let areaInSquareMeters = area
            let areaInSquareFeet = areaInSquareMeters * 10.764
            
            self.ceilingArea?.wrappedValue = String(format: "%.2f m² (%.2f sq ft)", areaInSquareMeters, areaInSquareFeet)
        }
    }
    
    private func calculateAndDisplayHeight() {
        guard let floorHeight = floorHeight, let ceilingHeight = ceilingHeight else { return }
        
        // Calculate height
        let height = abs(ceilingHeight - floorHeight)
        
        // Update UI with the height
        DispatchQueue.main.async {
            let heightMeters = Double(height)
            let heightFeet = Int(heightMeters * 3.28084)
            let heightInches = Int((heightMeters * 39.3701).truncatingRemainder(dividingBy: 12))
            
            self.measuredHeight?.wrappedValue = String(format: "%.2f m (%d' %d\")", heightMeters, heightFeet, heightInches)
            self.measurementAccuracy?.wrappedValue = 5.0 // Estimate accuracy
        }
    }
    
    // Function to calculate area of a polygon defined by points
    private func calculatePolygonArea(_ points: [SCNVector3]) -> Float {
        guard points.count >= 3 else { return 0 }
        
        var area: Float = 0
        
        // Use shoelace formula for polygon area
        for i in 0..<points.count {
            let j = (i + 1) % points.count
            // Project to 2D by using X and Z coordinates (ignoring Y which is height)
            area += points[i].x * points[j].z
            area -= points[j].x * points[i].z
        }
        
        return abs(area) / 2
    }
    
    // MARK: - Visual Elements
    
    private func createMarkerNode(color: UIColor) -> SCNNode {
        // Create a sphere to mark a point
        let sphere = SCNSphere(radius: 0.02)
        let material = SCNMaterial()
        material.diffuse.contents = color
        sphere.materials = [material]
        
        return SCNNode(geometry: sphere)
    }
    
    private func addLine(from: SCNVector3, to: SCNVector3, color: UIColor) {
        let lineGeometry = SCNGeometry.line(from: from, to: to)
        let material = SCNMaterial()
        material.diffuse.contents = color
        lineGeometry.materials = [material]
        
        let lineNode = SCNNode(geometry: lineGeometry)
        arView.scene.rootNode.addChildNode(lineNode)
    }
    
    private func updateFloorPolygon() {
        // Remove existing polygon
        floorPolygonNode?.removeFromParentNode()
        
        // Create new polygon if we have enough points
        if floorCorners.count >= 3 {
            let polygonNode = createPolygonNode(from: floorCorners, color: UIColor.green.withAlphaComponent(0.3))
            arView.scene.rootNode.addChildNode(polygonNode)
            floorPolygonNode = polygonNode
        }
    }
    
    private func updateCeilingPolygon() {
        // Remove existing polygon
        ceilingPolygonNode?.removeFromParentNode()
        
        // Create new polygon if we have enough points
        if ceilingCorners.count >= 3 {
            let polygonNode = createPolygonNode(from: ceilingCorners, color: UIColor.blue.withAlphaComponent(0.3))
            arView.scene.rootNode.addChildNode(polygonNode)
            ceilingPolygonNode = polygonNode
        }
    }
    
    private func createPolygonNode(from points: [SCNVector3], color: UIColor) -> SCNNode {
        // For simple visualization, we'll create a series of triangles
        // from the first point to each pair of consecutive points
        
        let polygonNode = SCNNode()
        
        // Need at least 3 points to create a polygon
        guard points.count >= 3 else { return polygonNode }
        
        // For each triplet of points, create a triangle
        for i in 1..<points.count-1 {
            let triangleGeometry = createTriangleGeometry(
                from: points[0],
                to: points[i],
                and: points[i+1],
                color: color
            )
            
            let triangleNode = SCNNode(geometry: triangleGeometry)
            polygonNode.addChildNode(triangleNode)
        }
        
        return polygonNode
    }
    
    private func createTriangleGeometry(from a: SCNVector3, to b: SCNVector3, and c: SCNVector3, color: UIColor) -> SCNGeometry {
        // Create vertices and faces for a triangle
        let vertices: [SCNVector3] = [a, b, c]
        
        // Create geometry sources
        let vertexSource = SCNGeometrySource(vertices: vertices)
        
        // Create geometry elements (faces)
        let indices: [Int32] = [0, 1, 2]
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        // Create geometry
        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        
        // Create material
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.isDoubleSided = true // Visible from both sides
        geometry.materials = [material]
        
        return geometry
    }
    
    // MARK: - Helper Methods
    
    // Add a visual instruction panel in AR space
    private func addInstructionPanel(text: String, at position: SCNVector3) {
        // Remove existing instruction node if any
        instructionNode?.removeFromParentNode()
        
        // Create a panel with text
        let panelNode = SCNNode()
        
        // Background panel
        let panel = SCNPlane(width: 0.3, height: 0.15)
        let panelMaterial = SCNMaterial()
        panelMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.7)
        panel.materials = [panelMaterial]
        
        let panelGeometry = SCNNode(geometry: panel)
        panelNode.addChildNode(panelGeometry)
        
        // Text
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: 0.02)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.1, 0.1, 0.1)
        
        // Center text on panel
        let (min, max) = textGeometry.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2, (max.y - min.y) / 2, 0)
        textNode.position = SCNVector3(-0.13, -0.05, 0.01)
        
        panelNode.addChildNode(textNode)
        
        // Position the panel
        panelNode.position = position
        
        // Make panel always face the camera
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = [.X, .Y, .Z]
        panelNode.constraints = [billboardConstraint]
        
        // Add to scene
        arView.scene.rootNode.addChildNode(panelNode)
        instructionNode = panelNode
    }
    
    // Update or add instruction text in AR space
    private func updateInstructionText(text: String) {
        if let camera = arView.pointOfView {
            // Position panel in front of and slightly below camera
            let cameraPosition = camera.position
            let cameraDirection = camera.look()
            
            // Calculate position 1 meter in front of camera, slightly down
            let position = SCNVector3(
                cameraPosition.x + cameraDirection.x,
                cameraPosition.y - 0.3,
                cameraPosition.z + cameraDirection.z
            )
            
            addInstructionPanel(text: text, at: position)
        }
    }
    
    // MARK: - Cleanup
    
    func pauseSession() {
        arView.session.pause()
        
        // Clean up resources
        floorMarkers.forEach { $0.removeFromParentNode() }
        ceilingMarkers.forEach { $0.removeFromParentNode() }
        floorPolygonNode?.removeFromParentNode()
        ceilingPolygonNode?.removeFromParentNode()
    }
}

// MARK: - Extensions

//extension SCNGeometry {
//    static func line(from: SCNVector3, to: SCNVector3) -> SCNGeometry {
//        let indices: [Int32] = [0, 1]
//        let source = SCNGeometrySource(vertices: [from, to])
//        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
//        return SCNGeometry(sources: [source], elements: [element])
//    }
//}

extension SCNNode {
    // Helper to get camera's forward direction
    func look() -> SCNVector3 {
        let direction = SCNVector3(0, 0, -1)
        return self.convertVector(direction, to: nil)
    }
}

extension SCNGeometry {
    /// Creates a simple line geometry between two 3D points.
    static func line(from start: SCNVector3, to end: SCNVector3) -> SCNGeometry {
        // 1. Define the two endpoints
        let vertices = [start, end]
        
        // 2. Create a geometry source from these vertices
        let vertexSource = SCNGeometrySource(vertices: vertices)
        
        // 3. Define the line indices (start to end)
        let indices: [Int32] = [0, 1]
        
        // 4. Create a geometry element with line primitive
        let geometryElement = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        // 5. Combine source + element into SCNGeometry
        let lineGeometry = SCNGeometry(sources: [vertexSource], elements: [geometryElement])
        
        return lineGeometry
    }
}
