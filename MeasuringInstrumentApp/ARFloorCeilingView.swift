//
//  ARFloorCeilingView.swift
//  MeasuringInstrumentApp
//
//  Created by Muntahaa Khan on 5/3/25.
//
import SwiftUI
import ARKit
import SceneKit

struct ARFloorCeilingView: UIViewControllerRepresentable {
    @Binding var measuredHeight: String

    func makeUIViewController(context: Context) -> ARViewController {
        let arVC = ARViewController()
        arVC.measuredHeight = $measuredHeight
        return arVC
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: ARViewController, coordinator: ()) {
        uiViewController.pauseSession() // Pause AR session when view is removed
    }
}

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    var arView: ARSCNView!
    var measuredHeight: Binding<String>?

    override func viewDidLoad() {
        super.viewDidLoad()

        arView = ARSCNView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.delegate = self
        view.addSubview(arView)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]

        arView.session.run(configuration)
        arView.session.delegate = self

        print("✅ ARKit session started")
    }

    // Function to properly pause the AR session
    func pauseSession() {
        print("🛑 Pausing AR Session")
        arView.session.pause()
    }

    deinit {
        pauseSession()
    }

    // ARKit delegate method to detect planes
    @objc func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                print("✅ Plane Detected: \(planeAnchor)")
            }
        }
    }
}
