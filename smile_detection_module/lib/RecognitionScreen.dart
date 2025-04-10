
/////below is code shown for sprint review 1

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:async';

// class RecognitionScreen extends StatefulWidget {
//   const RecognitionScreen({Key? key}) : super(key: key);

//   @override
//   State<RecognitionScreen> createState() => _RecognitionScreenState();
// }

// class _RecognitionScreenState extends State<RecognitionScreen> {
//   CameraController? _controller;
//   FaceDetector? _faceDetector;
//   bool _isSmiling = false;
//   bool _isProcessing = false;
//   XFile? _capturedImage;
//   Timer? _frameCheckTimer;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _faceDetector = GoogleMlKit.vision.faceDetector(
//       FaceDetectorOptions(enableClassification: true),
//     );
//   }

//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//     final frontCamera = cameras.firstWhere(
//       (camera) => camera.lensDirection == CameraLensDirection.front,
//       orElse: () => cameras.first,
//     );

//     _controller = CameraController(
//       frontCamera,
//       ResolutionPreset.medium,
//       enableAudio: false,
//     );

//     await _controller!.initialize();
//     if (!mounted) return;

//     setState(() {});
//     _startSmileDetection();
//   }

//   void _startSmileDetection() {
//     _frameCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (_controller != null && _controller!.value.isInitialized) {
//         _controller!.takePicture().then((XFile image) {
//           _processImage(image);
//         });
//       }
//     });
//   }

//   Future<void> _processImage(XFile image) async {
//     if (_isProcessing) return;
//     _isProcessing = true;

//     final inputImage = InputImage.fromFilePath(image.path);
//     final faces = await _faceDetector!.processImage(inputImage);

//     if (faces.isNotEmpty && faces.first.smilingProbability != null) {
//       double smileProb = faces.first.smilingProbability!;
//       setState(() => _isSmiling = smileProb > 0.7);

//       if (_isSmiling) {
//         _frameCheckTimer?.cancel(); // Stop processing frames after capturing
//         _capturedImage = image;
//         setState(() {}); // Update UI to show the captured image
//       }
//     }

//     _isProcessing = false;
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _faceDetector?.close();
//     _frameCheckTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Live Smile Detection")),
//       body: Column(
//         children: [
//           Expanded(
//             child: _capturedImage == null
//                 ? (_controller == null || !_controller!.value.isInitialized
//                     ? const Center(child: CircularProgressIndicator())
//                     : Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           CameraPreview(_controller!),
//                           if (_isSmiling)
//                             const Positioned(
//                               top: 20,
//                               child: Text(
//                                 "😊 Keep Smiling! 😊",
//                                 style: TextStyle(
//                                   color: Colors.green,
//                                   fontSize: 22,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ))
//                 : Image.file(File(_capturedImage!.path)),
//           ),
//           if (_capturedImage != null)
//             Column(
//               children: [
//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() => _capturedImage = null);
//                     _startSmileDetection(); // Restart detection
//                   },
//                   child: const Text("Retake"),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({Key? key}) : super(key: key);

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isSmiling = false;
  bool _isProcessing = false;
  XFile? _capturedImage;
  Timer? _frameCheckTimer;
  
  // Form fields
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _rollNumber = '';
  String _phoneNumber = '';
  bool _showIdCard = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(enableClassification: true),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() {});
    _startSmileDetection();
  }

  void _startSmileDetection() {
    _frameCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_controller != null && _controller!.value.isInitialized) {
        _controller!.takePicture().then((XFile image) {
          _processImage(image);
        });
      }
    });
  }

  Future<void> _processImage(XFile image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final inputImage = InputImage.fromFilePath(image.path);
    final faces = await _faceDetector!.processImage(inputImage);

    if (faces.isNotEmpty && faces.first.smilingProbability != null) {
      double smileProb = faces.first.smilingProbability!;
      setState(() => _isSmiling = smileProb > 0.7);

      if (_isSmiling) {
        _frameCheckTimer?.cancel();
        _capturedImage = image;
        setState(() {});
      }
    }

    _isProcessing = false;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _showIdCard = true;
      });
    }
  }

  void _resetProcess() {
    setState(() {
      _capturedImage = null;
      _showIdCard = false;
      _name = '';
      _rollNumber = '';
      _phoneNumber = '';
    });
    _startSmileDetection();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector?.close();
    _frameCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Smile Detection")),
      body: _showIdCard 
          ? _buildIdCard()
          : Column(
              children: [
                Expanded(
                  child: _capturedImage == null
                      ? (_controller == null || !_controller!.value.isInitialized
                          ? const Center(child: CircularProgressIndicator())
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                CameraPreview(_controller!),
                                if (_isSmiling)
                                  const Positioned(
                                    top: 20,
                                    child: Text(
                                      "😊 Keep Smiling! 😊",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ))
                      : _buildDetailsForm(),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Image.file(File(_capturedImage!.path)),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Roll Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your roll number';
                }
                return null;
              },
              onSaved: (value) => _rollNumber = value!,
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length != 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
              onSaved: (value) => _phoneNumber = value!,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _resetProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Retake Photo"),
                ),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("Generate ID Card"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdCard() {
  return Center(
    child: Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.white],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            const Text(
              "SCHOOL ID CARD",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 2,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Image.file(
                    File(_capturedImage!.path),
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIdCardRow("Name:", _name),
                      _buildIdCardRow("Roll No:", _rollNumber),
                      _buildIdCardRow("Phone:", _phoneNumber),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          "Valid for current academic year",
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
              ),
              alignment: Alignment.center,
              child: const Text(
                "Authorized School Stamp",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetProcess,
              child: const Text("Create New ID"),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildIdCardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: " $value"),
          ],
        ),
      ),
    );
  }
}