//
//  ARHeightMeasurementView.swift
//  MeasuringInstrumentApp
//
//  Created by Muntahaa Khan on 19/3/25.
//

import SwiftUI
import ARKit
import SceneKit

struct ARHeightMeasurementView: UIViewControllerRepresentable {
    @Binding var measuredHeight: String

    func makeUIViewController(context: Context) -> ARHeightMeasurementViewController {
        let arVC = ARHeightMeasurementViewController()
        arVC.measuredHeight = $measuredHeight
        return arVC
    }

    func updateUIViewController(_ uiViewController: ARHeightMeasurementViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: ARHeightMeasurementViewController, coordinator: ()) {
        uiViewController.pauseSession()
    }
}

class ARHeightMeasurementViewController: UIViewController, ARSessionDelegate {
    var arView: ARSCNView!
    var measuredHeight: Binding<String>?

    override func viewDidLoad() {
        super.viewDidLoad()

        arView = ARSCNView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.session.delegate = self
        view.addSubview(arView)

        let configuration = ARBodyTrackingConfiguration()
        arView.session.run(configuration)

        print("✅ ARKit session started for Height Measurement")
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                let height = calculateHeight(bodyAnchor: bodyAnchor)
                let heightText = String(format: "%.2f cm", height)
                measuredHeight?.wrappedValue = "Measured Height: \(heightText)"
                print("📏 Detected Height: \(heightText) cm")
            }
        }
    }

    func calculateHeight(bodyAnchor: ARBodyAnchor) -> CGFloat {
        let skeleton = bodyAnchor.skeleton
        guard let headTransform = skeleton.modelTransform(for: .head),
              let footTransform = skeleton.modelTransform(for: .leftFoot) else { return 0 }

        let headY = CGFloat(headTransform.columns.3.y) // Convert to CGFloat
        let footY = CGFloat(footTransform.columns.3.y) // Convert to CGFloat
        let heightInMeters = headY - footY
        return heightInMeters * 100.0 // Convert to cm
    }

    func pauseSession() {
        arView.session.pause()
    }

    deinit {
        pauseSession()
    }
}
