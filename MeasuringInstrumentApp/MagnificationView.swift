import SwiftUI
import AVFoundation

struct MagnificationView: View {
    @State private var zoomFactor: CGFloat = 1.0
    @State private var isFlashOn: Bool = false
    
    var body: some View {
        VStack {
            Text("🔍 Magnification/Telescope")
                .font(.title)
                .padding()
            
            CameraView(zoomFactor: $zoomFactor, isFlashOn: $isFlashOn) // Camera preview
                .ignoresSafeArea()
                .frame(height: 500)
            
            Slider(value: $zoomFactor, in: 1.0...10.0, step: 0.1)
                .padding()
            
            Text("Zoom: \(String(format: "%.1f", zoomFactor))x")
                .font(.headline)
                .padding()
            
            Button(action: {
                isFlashOn.toggle()
            }) {
                Text(isFlashOn ? "🔦 Turn Off Flashlight" : "💡 Turn On Flashlight")
                    .padding()
                    .background(isFlashOn ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

// UIKit Wrapper for AVCaptureSession
struct CameraView: UIViewControllerRepresentable {
    @Binding var zoomFactor: CGFloat
    @Binding var isFlashOn: Bool // ✅ Explicit type annotation
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC: CameraViewController = CameraViewController() // ✅ Explicit type annotation
        cameraVC.zoomFactor = zoomFactor
        return cameraVC
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.updateZoom(zoomFactor: zoomFactor)
        uiViewController.toggleFlashlight(isOn: isFlashOn)
    }
}

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var zoomFactor: CGFloat = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { // Move to background thread
            self.captureSession = AVCaptureSession()
            print("✅ Initializing AVCaptureSession")

            guard let videoCaptureDevice: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("❌ No camera available")
                return
            }

            do {
                let videoInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    print("✅ Camera input added")
                } else {
                    print("❌ Failed to add camera input")
                }
            } catch {
                print("❌ Error setting up camera input: \(error)")
            }

            self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.videoPreviewLayer.videoGravity = .resizeAspectFill

            DispatchQueue.main.async { // Ensure UI updates happen on main thread
                self.videoPreviewLayer.frame = self.view.layer.bounds
                self.view.layer.addSublayer(self.videoPreviewLayer)
            }

            self.captureSession.startRunning() // Now running on background thread
            print("✅ Camera session started")
        }
    }
    
    func updateZoom(zoomFactor: CGFloat) {
        guard let device: AVCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoomFactor
            device.unlockForConfiguration()
        } catch {
            print("Error adjusting zoom: \(error)")
        }
    }
    
    // ✅ Toggle Flashlight
    func toggleFlashlight(isOn: Bool) {
        guard let device: AVCaptureDevice = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("❌ Flashlight not available")
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
            print(isOn ? "✅ Flashlight turned ON" : "✅ Flashlight turned OFF")
        } catch {
            print("❌ Error toggling flashlight: \(error)")
        }
    }
}

struct MagnificationView_Previews: PreviewProvider {
    static var previews: some View {
        MagnificationView()
    }
}
