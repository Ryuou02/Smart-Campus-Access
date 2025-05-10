// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:smart_campus_access/models/user.dart';
// import 'package:smart_campus_access/services/mongodb_service.dart';
// import 'package:smart_campus_access/widgets/id_card_widget.dart';
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

//   final _formKey = GlobalKey<FormState>();
//   String _name = '';
//   String _rollNumber = '';
//   String _phoneNumber = '';
//   String _year = '';
//   String _degree = '';
//   String _specialization = '';
//   bool _showIdCard = false;

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
//         _frameCheckTimer?.cancel();
//         _capturedImage = image;
//         setState(() {});
//       }
//     }

//     _isProcessing = false;
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//       final user = User(
//         email: '$_rollNumber@campus.com', // Auto-generate email
//         password: 'password123', // Default password
//         role: 'student',
//         name: _name,
//         rollNumber: _rollNumber,
//         phoneNumber: _phoneNumber,
//         year: _year,
//         degree: _degree,
//         specialization: _specialization,
//         photoPath: _capturedImage!.path,
//       ).toMap();

//       await MongoDBService.insertUser(user);
//       setState(() {
//         _showIdCard = true;
//       });
//     }
//   }

//   void _resetProcess() {
//     setState(() {
//       _capturedImage = null;
//       _showIdCard = false;
//       _name = '';
//       _rollNumber = '';
//       _phoneNumber = '';
//       _year = '';
//       _degree = '';
//       _specialization = '';
//     });
//     _startSmileDetection();
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
//       body: _showIdCard
//           ? IdCardWidget(
//               name: _name,
//               rollNumber: _rollNumber,
//               phoneNumber: _phoneNumber,
//               year: _year,
//               degree: _degree,
//               specialization: _specialization,
//               photoPath: _capturedImage!.path,
//               onReset: () => Navigator.pop(context),
//             )
//           : Column(
//               children: [
//                 Expanded(
//                   child: _capturedImage == null
//                       ? (_controller == null || !_controller!.value.isInitialized
//                           ? const Center(child: CircularProgressIndicator())
//                           : Stack(
//                               alignment: Alignment.center,
//                               children: [
//                                 CameraPreview(_controller!),
//                                 if (_isSmiling)
//                                   const Positioned(
//                                     top: 20,
//                                     child: Text(
//                                       "😊 Keep Smiling! 😊",
//                                       style: TextStyle(
//                                         color: Colors.green,
//                                         fontSize: 22,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                               ],
//                             ))
//                       : _buildDetailsForm(),
//                 ),
//               ],
//             ),
//     );
//   }

//   Widget _buildDetailsForm() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             Image.file(File(_capturedImage!.path)),
//             const SizedBox(height: 20),
//             TextFormField(
//               decoration: const InputDecoration(
//                 labelText: 'Name',
//                 border: OutlineInputBorder(),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your name';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _name = value!,
//             ),
//             const SizedBox(height: 15),
//             TextFormField(
//               decoration: const InputDecoration(
//                 labelText: 'Roll Number',
//                 border: OutlineInputBorder(),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your roll number';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _rollNumber = value!,
//             ),
//             const SizedBox(height: 15),
//             TextFormField(
//               decoration: const InputDecoration(
//                 labelText: 'Phone Number',
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.phone,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your phone number';
//                 }
//                 if (value.length != 10) {
//                   return 'Please enter a valid 10-digit phone number';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _phoneNumber = value!,
//             ),
//             const SizedBox(height: 15),
//             TextFormField(
//               decoration: const InputDecoration(
//                 labelText: 'Year',
//                 border: OutlineInputBorder(),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your year';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _year = value!,
//             ),
//             const SizedBox(height: 15),
//             TextFormField(
//               decoration: const InputDecoration(
//                 labelText: 'Degree',
//                 border: OutlineInputBorder(),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your degree';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _degree = value!,
//             ),
//             const SizedBox(height: 15),
//             TextFormField(
//               decoration: const InputDecoration(
//                 labelText: 'Specialization',
//                 border: OutlineInputBorder(),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your specialization';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _specialization = value!,
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: _resetProcess,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                   ),
//                   child: const Text("Retake Photo"),
//                 ),
//                 ElevatedButton(
//                   onPressed: _submitForm,
//                   child: const Text("Generate ID Card"),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert'; // Added for base64 encoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:smart_campus_access/models/user.dart';
import 'package:smart_campus_access/services/mongodb_service.dart';
import 'package:smart_campus_access/widgets/id_card_widget.dart';
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
  String? _capturedImageBase64; // Added to store base64 string
  Timer? _frameCheckTimer;

  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _rollNumber = '';
  String _phoneNumber = '';
  String _year = '';
  String _degree = '';
  String _specialization = '';
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
        final bytes = await File(image.path).readAsBytes();
        _capturedImageBase64 = base64Encode(bytes); // Convert to base64
        _capturedImage = image;
        setState(() {});
      }
    }

    _isProcessing = false;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Check if a student with this roll number already exists
      final existingUser = await MongoDBService.getUserByRollNumber(_rollNumber);
      if (existingUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No student found with this roll number. Please register the student first.")),
        );
        return;
      }

      // Update the existing user with ID card details
      final updatedUser = {
        'name': _name,
        'rollNumber': _rollNumber,
        'phoneNumber': _phoneNumber,
        'year': _year,
        'degree': _degree,
        'specialization': _specialization,
        'photoData': _capturedImageBase64, // Changed to photoData with base64 string
      };

      await MongoDBService.updateUserByRollNumber(_rollNumber, updatedUser);

      setState(() {
        _showIdCard = true;
      });
    }
  }

  void _resetProcess() {
    setState(() {
      _capturedImage = null;
      _capturedImageBase64 = null; // Reset base64 string
      _showIdCard = false;
      _name = '';
      _rollNumber = '';
      _phoneNumber = '';
      _year = '';
      _degree = '';
      _specialization = '';
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
          ? IdCardWidget(
              name: _name,
              rollNumber: _rollNumber,
              phoneNumber: _phoneNumber,
              year: _year,
              degree: _degree,
              specialization: _specialization,
              photoData: _capturedImageBase64, // Changed to photoData with base64 string
              qrCodeId: _rollNumber,
              onReset: () => Navigator.pop(context),
            )
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
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your year';
                }
                return null;
              },
              onSaved: (value) => _year = value!,
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Degree',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your degree';
                }
                return null;
              },
              onSaved: (value) => _degree = value!,
            ),
            const SizedBox(height: 15),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Specialization',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your specialization';
                }
                return null;
              },
              onSaved: (value) => _specialization = value!,
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
}