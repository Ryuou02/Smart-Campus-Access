import 'dart:convert'; // Added for base64 encoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:smart_campus_access/models/user.dart';
import 'package:smart_campus_access/services/mongodb_service.dart';
import 'package:smart_campus_access/widgets/id_card_widget.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late ImagePicker imagePicker;
  File? _image;
  String? _imageBase64; // Added to store base64 string
  FaceDetector? faceDetector;
  bool _showForm = false;
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
        final bytes = await tempImage.readAsBytes();
        _imageBase64 = base64Encode(bytes); // Convert to base64
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
          final bytes = await tempImage.readAsBytes();
          _imageBase64 = base64Encode(bytes); // Convert to base64
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
        'photoData': _imageBase64, // Changed to photoData with base64 string
      };

      await MongoDBService.updateUserByRollNumber(_rollNumber, updatedUser);

      setState(() {
        _showForm = false;
        _showIdCard = true;
      });
    }
  }

  void _resetProcess() {
    setState(() {
      _image = null;
      _imageBase64 = null; // Reset base64 string
      _showForm = false;
      _showIdCard = false;
      _name = '';
      _rollNumber = '';
      _phoneNumber = '';
      _year = '';
      _degree = '';
      _specialization = '';
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
          ? IdCardWidget(
              name: _name,
              rollNumber: _rollNumber,
              phoneNumber: _phoneNumber,
              year: _year,
              degree: _degree,
              specialization: _specialization,
              photoData: _imageBase64, // Changed to photoData with base64 string
              qrCodeId: _rollNumber,
              onReset: () => Navigator.pop(context),
            )
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera),
              label: const Text("Camera"),
              onPressed: _imgFromCamera,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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