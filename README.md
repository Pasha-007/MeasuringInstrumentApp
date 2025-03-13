📏 Measuring Instrument App

A Swift-based iOS application that provides AR-powered measurement tools for various purposes, including floor-to-ceiling height, magnification (telescope mode), and object size measurement. Built using ARKit & AVFoundation.

🚀 Features

Floor & Ceiling Measurement – Measures vertical distances using AR.

Magnification (Telescope Mode) – Enhances objects using zoom & digital processing.

Object Size Measurement – Measures the distance between two points in AR.

Multiple Measurements – Supports persistent measurement lines.

Real-time 2D Labels – Displays measurements directly on screen.

📲 Installation

1️⃣ Clone the Repository

git clone https://github.com/yourusername/MeasuringInstrumentApp.git
cd MeasuringInstrumentApp
open MeasuringInstrumentApp.xcodeproj

2️⃣ Open in Xcode

Requires Xcode 15+.

Connect an iPhone with iOS 17+ (AR features do not work in Simulator).

Ensure you have a Developer Account signed in (Signing & Capabilities tab).

3️⃣ Run the App on a Physical Device

Select your iPhone as the build target.

Click Run (Cmd + R).

🛠️ Technologies Used

Swift – Core development language.

ARKit – Used for object & space measurement.

AVFoundation – Handles magnification & camera control.

SceneKit – Renders 3D objects in AR.

UIKit & SwiftUI – Provides UI for measurement tools.

🎯 Usage Guide

1️⃣ Floor & Ceiling Measurement

Tap to place points at floor and ceiling.

Displays real-time distance.

2️⃣ Object Size Measurement

Tap two points on an object to measure its length.

Measurement lines & labels persist.

3️⃣ Magnification Mode

Use slider to zoom up to 50x.

Uses optical + digital zoom with real-time image cropping.

⚡ Future Improvements

✅ Save Measurements (Export as images/PDF).

✅ Better Accuracy (Calibrate using known objects).

✅ Edge Detection for improved precision.

✅ iPad Support (Larger screen UI optimizations).

🤝 Contributing

Want to improve this project? Fork the repo and submit a pull request!

Fork this repository

Create a feature branch (git checkout -b feature-name)

Commit changes (git commit -m "Added feature-name")

Push to the branch (git push origin feature-name)

Submit a Pull Request

🐝 License

This project is licensed under the MIT License.See the LICENSE file for more details.

💌 Contact

Developed by Muntahaa Khan
Feel free to reach out on GitHub
