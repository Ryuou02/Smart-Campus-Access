// import 'dart:io';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

// import 'package:image/image.dart' as img;

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({Key? key}) : super(key: key);

//   @override
//   State<RegistrationScreen> createState() => _HomePageState();
// }

// class _HomePageState extends State<RegistrationScreen> {
//   //TODO declare variables
//   late ImagePicker imagePicker;
//   File? _image;

//   //TODO declare detector
//   late FaceDetector faceDetector;

//   //TODO declare face recognizer

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     imagePicker = ImagePicker();

//     //TODO initialize face detector
//     final options = FaceDetectorOptions(
//       performanceMode: FaceDetectorMode.accurate,
//     );
//     faceDetector = FaceDetector(options: options);

//     //TODO initialize face recognizer
//   }

//   //TODO capture image using camera
//   _imgFromCamera() async {
//     XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         doFaceDetection();
//       });
//     }
//   }

//   //TODO choose image using gallery
//   _imgFromGallery() async {
//     XFile? pickedFile = await imagePicker.pickImage(
//       source: ImageSource.gallery,
//     );
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//         doFaceDetection();
//       });
//     }
//   }

//   //TODO face detection code here

//   doFaceDetection() async {
//     //TODO remove rotation of camera images

//     InputImage inputImage = InputImage.fromFile(_image!);
//     //TODO passing input to face detector and getting detected faces
//     final List<Face> faces = await faceDetector.processImage(inputImage);

//     for (Face face in faces) {
//       final Rect boundingBox = face.boundingBox;

//       final double? rotX = face.headEulerAngleX; // Head is tilted up and down rotX degrees
//       final double? rotY = face.headEulerAngleY; // Head is rotated to the right rotY degrees
//       final double? rotZ = face.headEulerAngleZ; // Head is tilted sideways rotZ degrees

//       // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
//       // eyes, cheeks, and nose available):
//       final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
//       if (leftEar != null) {
//         final Point<int> leftEarPos = leftEar.position;
//       }

//       // If classification was enabled with FaceDetectorOptions:
//       if (face.smilingProbability != null) {
//         final double? smileProb = face.smilingProbability;
//       }

//       // If face tracking was enabled with FaceDetectorOptions:
//       if (face.trackingId != null) {
//         final int? id = face.trackingId;
//       }
//     }

//     //TODO call the method to perform face recognition on detected faces
//   }

//   //TODO remove rotation of camera images
//   removeRotation(File inputImage) async {
//     final img.Image? capturedImage = img.decodeImage(
//       await File(inputImage.path).readAsBytes(),
//     );
//     final img.Image orientedImage = img.bakeOrientation(capturedImage!);
//     return await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
//   }

//   //TODO perform Face Recognition

//   //TODO Face Registration Dialogue
//   // TextEditingController textEditingController = TextEditingController();
//   // showFaceRegistrationDialogue(Uint8List cropedFace, Recognition recognition){
//   //   showDialog(
//   //     context: context,
//   //     builder: (ctx) => AlertDialog(
//   //       title: const Text("Face Registration",textAlign: TextAlign.center),alignment: Alignment.center,
//   //       content: SizedBox(
//   //         height: 340,
//   //         child: Column(
//   //           crossAxisAlignment: CrossAxisAlignment.center,
//   //           children: [
//   //             const SizedBox(height: 20,),
//   //             Image.memory(
//   //               cropedFace,
//   //               width: 200,
//   //               height: 200,
//   //             ),
//   //             SizedBox(
//   //               width: 200,
//   //               child: TextField(
//   //                 controller: textEditingController,
//   //                   decoration: const InputDecoration( fillColor: Colors.white, filled: true,hintText: "Enter Name")
//   //               ),
//   //             ),
//   //             const SizedBox(height: 10,),
//   //             ElevatedButton(
//   //                 onPressed: () {
//   //                   recognizer.registerFaceInDB(textEditingController.text, recognition.embeddings);
//   //                   textEditingController.text = "";
//   //                   Navigator.pop(context);
//   //                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//   //                     content: Text("Face Registered"),
//   //                   ));
//   //                 },style: ElevatedButton.styleFrom(primary:Colors.blue,minimumSize: const Size(200,40)),
//   //                 child: const Text("Register"))
//   //           ],
//   //         ),
//   //       ),contentPadding: EdgeInsets.zero,
//   //     ),
//   //   );
//   // }
//   //TODO draw rectangles
//   // var image;
//   // drawRectangleAroundFaces() async {
//   //   image = await _image?.readAsBytes();
//   //   image = await decodeImageFromList(image);
//   //   print("${image.width}   ${image.height}");
//   //   setState(() {
//   //     image;
//   //     faces;
//   //   });
//   // }

//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _image != null
//               ? Container(
//                 margin: const EdgeInsets.only(top: 100),
//                 width: screenWidth - 50,
//                 height: screenWidth - 50,
//                 child: Image.file(_image!),
//               )
//               // Container(
//               //   margin: const EdgeInsets.only(
//               //       top: 60, left: 30, right: 30, bottom: 0),
//               //   child: FittedBox(
//               //     child: SizedBox(
//               //       width: image.width.toDouble(),
//               //       height: image.width.toDouble(),
//               //       child: CustomPaint(
//               //         painter: FacePainter(
//               //             facesList: faces, imageFile: image),
//               //       ),
//               //     ),
//               //   ),
//               // )
//               : Container(
//                 margin: const EdgeInsets.only(top: 100),
//                 child: Image.asset(
//                   "images/logo.png",
//                   width: screenWidth - 100,
//                   height: screenWidth - 100,
//                 ),
//               ),

//           Container(height: 50),

//           //TODO section which displays buttons for choosing and capturing images
//           Container(
//             margin: const EdgeInsets.only(bottom: 50),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Card(
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.all(Radius.circular(200)),
//                   ),
//                   child: InkWell(
//                     onTap: () {
//                       _imgFromGallery();
//                     },
//                     child: SizedBox(
//                       width: screenWidth / 2 - 70,
//                       height: screenWidth / 2 - 70,
//                       child: Icon(
//                         Icons.image,
//                         color: Colors.blue,
//                         size: screenWidth / 7,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Card(
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.all(Radius.circular(200)),
//                   ),
//                   child: InkWell(
//                     onTap: () {
//                       _imgFromCamera();
//                     },
//                     child: SizedBox(
//                       width: screenWidth / 2 - 70,
//                       height: screenWidth / 2 - 70,
//                       child: Icon(
//                         Icons.camera,
//                         color: Colors.blue,
//                         size: screenWidth / 7,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // class FacePainter extends CustomPainter {
// //   List<Face> facesList;
// //   dynamic imageFile;
// //   FacePainter({required this.facesList, @required this.imageFile});
// //
// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     if (imageFile != null) {
// //       canvas.drawImage(imageFile, Offset.zero, Paint());
// //     }
// //
// //     Paint p = Paint();
// //     p.color = Colors.red;
// //     p.style = PaintingStyle.stroke;
// //     p.strokeWidth = 3;
// //
// //     for (Face face in facesList) {
// //       canvas.drawRect(face.boundingBox, p);
// //     }
// //   }
// //
// //   @override
// //   bool shouldRepaint(CustomPainter oldDelegate) {
// //     return true;
// //   }
// // }




////////////////////////
///
///
///
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:flutter/material.dart';  // Import Flutter UI components
// import 'package:path/path.dart' as path;  // Use an alias to prevent conflicts




// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({Key? key}) : super(key: key);

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   late ImagePicker imagePicker;
//   File? _image;
//   FaceDetector? faceDetector;
//   List<Face> faces = [];
//   late Database database;

//   @override
//   void initState() {
//     super.initState();
//     imagePicker = ImagePicker();
//     faceDetector = GoogleMlKit.vision.faceDetector(
//       FaceDetectorOptions(
//         enableContours: true,
//         enableClassification: true,
//       ),
//     );
//     _initDatabase();
//   }

//   Future<void> _initDatabase() async {
//     database = await openDatabase(
//       path.join(await getDatabasesPath(), 'face_recognition.db'),
//       onCreate: (db, version) {
//         return db.execute(
//           "CREATE TABLE faces(id INTEGER PRIMARY KEY, name TEXT, embedding BLOB)",
//         );
//       },
//       version: 1,
//     );
//   }

//   Future<void> _imgFromCamera() async {
//     XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//       await doFaceDetection();
//     }
//   }

//   Future<void> _imgFromGallery() async {
//     XFile? pickedFile =
//         await imagePicker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//       await doFaceDetection();
//     }
//   }

//   Future<void> doFaceDetection() async {
//     final img.Image? capturedImage =
//         img.decodeImage(await _image!.readAsBytes());
//     final img.Image orientedImage = img.bakeOrientation(capturedImage!);
//     await _image!.writeAsBytes(img.encodeJpg(orientedImage));

//     final InputImage inputImage = InputImage.fromFile(_image!);
//     faces = await faceDetector!.processImage(inputImage);

//     if (faces.isNotEmpty) {
//       _showFaceRegistrationDialog();
//     }
//   }

//   void _showFaceRegistrationDialog() {
//     TextEditingController textController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Face Registration"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.file(_image!, width: 100, height: 100),
//             TextField(
//               controller: textController,
//               decoration: const InputDecoration(hintText: "Enter Name"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 await database.insert(
//                   'faces',
//                   {'name': textController.text, 'embedding': "face_data"},
//                   conflictAlgorithm: ConflictAlgorithm.replace,
//                 );
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Face Registered")),
//                 );
//               },
//               child: const Text("Register"),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     faceDetector?.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Face Registration")),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _image != null
//               ? Image.file(_image!, width: 200, height: 200)
//               : const Icon(Icons.face, size: 100),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.image),
//                 label: const Text("Gallery"),
//                 onPressed: _imgFromGallery,
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.camera),
//                 label: const Text("Camera"),
//                 onPressed: _imgFromCamera,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }








/////////////////////
/// below code used in sprint 1
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
// import 'package:image/image.dart' as img;

// class RegistrationScreen extends StatefulWidget {
//   const RegistrationScreen({Key? key}) : super(key: key);

//   @override
//   State<RegistrationScreen> createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   late ImagePicker imagePicker;
//   File? _image;
//   FaceDetector? faceDetector;

//   @override
//   void initState() {
//     super.initState();
//     imagePicker = ImagePicker();
//     faceDetector = GoogleMlKit.vision.faceDetector(
//       FaceDetectorOptions(enableClassification: true),
//     );
//   }

//   Future<void> _imgFromGallery() async {
//     XFile? pickedFile =
//         await imagePicker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() => _image = File(pickedFile.path));
//     }
//   }

//   Future<void> _imgFromCamera() async {
//     while (true) {
//       XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
//       if (pickedFile != null) {
//         File tempImage = File(pickedFile.path);
//         final InputImage inputImage = InputImage.fromFile(tempImage);
//         final List<Face> faces = await faceDetector!.processImage(inputImage);

//         if (faces.isNotEmpty && faces[0].smilingProbability != null &&
//             faces[0].smilingProbability! > 0.5) {
//           setState(() => _image = tempImage);
//           break;
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Smile to capture the photo!")),
//           );
//         }
//       } else {
//         break; 
//       }
//     }
//   }

//   @override
//   void dispose() {
//     faceDetector?.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Smile to Capture")),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           _image != null
//               ? Image.file(_image!, width: 200, height: 200)
//               : const Icon(Icons.face, size: 100),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.image),
//                 label: const Text("Gallery"),
//                 onPressed: _imgFromGallery,
//               ),
//               const SizedBox(width: 10),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.camera),
//                 label: const Text("Camera"),
//                 onPressed: _imgFromCamera,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }




/////
///
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late ImagePicker imagePicker;
  File? _image;
  FaceDetector? faceDetector;
  bool _showForm = false;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _rollNumber = '';
  String _phoneNumber = '';
  bool _showIdCard = false;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(enableClassification: true),
    );
  }

  Future<void> _imgFromGallery() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File tempImage = File(pickedFile.path);
      final InputImage inputImage = InputImage.fromFile(tempImage);
      final List<Face> faces = await faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty && 
          faces[0].smilingProbability != null && 
          faces[0].smilingProbability! > 0.5) {
        setState(() {
          _image = tempImage;
          _showForm = true;
        });
      } else {
        setState(() {
          _image = tempImage;
          _showForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Smile not detected in the photo!"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _imgFromCamera() async {
    while (true) {
      XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        File tempImage = File(pickedFile.path);
        final InputImage inputImage = InputImage.fromFile(tempImage);
        final List<Face> faces = await faceDetector!.processImage(inputImage);

        if (faces.isNotEmpty && 
            faces[0].smilingProbability != null && 
            faces[0].smilingProbability! > 0.7) {
          setState(() {
            _image = tempImage;
            _showForm = true;
          });
          break;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Smile to capture the photo!"),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        break;
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _showForm = false;
        _showIdCard = true;
      });
    }
  }

  void _resetProcess() {
    setState(() {
      _image = null;
      _showForm = false;
      _showIdCard = false;
      _name = '';
      _rollNumber = '';
      _phoneNumber = '';
    });
  }

  @override
  void dispose() {
    faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smile to Capture")),
      body: _showIdCard
          ? _buildIdCard()
          : _showForm
              ? _buildDetailsForm()
              : _buildCaptureScreen(),
    );
  }

  Widget _buildCaptureScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _image != null
            ? Image.file(_image!, width: 200, height: 200)
            : const Icon(Icons.face, size: 100),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Gallery"),
              onPressed: _imgFromGallery,
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera),
              label: const Text("Camera"),
              onPressed: _imgFromCamera,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Image.file(_image!, width: 200, height: 200),
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
                      _image!,
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