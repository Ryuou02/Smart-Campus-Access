
import 'dart:convert'; // Add this import for base64 decoding
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:smart_campus_access/screens/login_screen.dart';
import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;

class FacultyScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const FacultyScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String _formTitle = '';
  String _question1 = '';
  String _question2 = '';
  bool _isLoading = false;
  bool _isScanning = false;
  List<Map<String, dynamic>> _feedbackForms = [];
  Map<String, List<Map<String, dynamic>>> _responses = {};
  List<Map<String, dynamic>> _attendanceLogs = [];
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _filteredAttendanceLogs = [];
  QRViewController? controller;
  String? scannedQrCode;
  Map<String, dynamic>? _scannedUser;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _fetchFeedbackForms();
      await _fetchAttendanceLogs();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _fetchFeedbackForms() async {
    final forms = await mongo.MongoDBService.getFeedbackFormsByFaculty(widget.user['rollNumber']);
    setState(() {
      _feedbackForms = forms;
    });
  }

  Future<void> _fetchAttendanceLogs() async {
    final logs = await mongo.MongoDBService.getAttendanceLogsByFaculty(widget.user['rollNumber']);
    setState(() {
      _attendanceLogs = logs;
    });
    if (_selectedDate != null) {
      await _filterAttendanceLogsByDate();
    }
  }

  Future<void> _createFeedbackForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final form = {
        'title': _formTitle,
        'facultyRollNumber': widget.user['rollNumber'],
        'questions': [
          _question1,
          _question2,
        ],
        'createdAt': DateTime.now().toIso8601String(),
      };

      await mongo.MongoDBService.createFeedbackForm(form);
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback form created successfully")),
      );

      _formKey.currentState!.reset();
      await _fetchFeedbackForms();
    }
  }

  Future<void> _viewResponses(String formId) async {
    final responses = await mongo.MongoDBService.getFeedbackResponsesByFormId(formId);
    setState(() {
      _responses[formId] = responses;
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code != null) {
        setState(() {
          scannedQrCode = scanData.code;
        });
        final user = await mongo.MongoDBService.getUserByQrCodeId(scanData.code!);
        if (user != null && user['role'] == 'student') {
          setState(() {
            _scannedUser = user;
          });
          controller.pauseCamera();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid QR code or user not a student")),
          );
        }
      }
    });
  }

  Future<void> _markAttendance() async {
    if (_scannedUser == null || scannedQrCode == null) return;

    final attendance = {
      'studentRollNumber': _scannedUser!['rollNumber'],
      'facultyRollNumber': widget.user['rollNumber'],
      'timestamp': DateTime.now().toIso8601String(),
    };

    await mongo.MongoDBService.logAttendance(attendance);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Attendance marked for ${_scannedUser!['rollNumber']}")),
    );

    setState(() {
      _scannedUser = null;
      scannedQrCode = null;
    });

    controller?.resumeCamera();
    await _fetchAttendanceLogs();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _filterAttendanceLogsByDate();
    }
  }

  Future<void> _filterAttendanceLogsByDate() async {
    if (_selectedDate == null) {
      setState(() {
        _filteredAttendanceLogs = [];
      });
      return;
    }

    final selectedDateStr = _selectedDate!.toIso8601String().substring(0, 10); // YYYY-MM-DD
    final Map<String, Map<String, dynamic>> consolidatedLogs = {};

    for (var log in _attendanceLogs) {
      final logDate = log['timestamp'].substring(0, 10);
      if (logDate == selectedDateStr) {
        final studentRollNumber = log['studentRollNumber'];
        if (!consolidatedLogs.containsKey(studentRollNumber)) {
          final photoData = await _fetchStudentPhoto(studentRollNumber);
          print('Fetched photoData for $studentRollNumber: ${photoData?.substring(0, 50)}...'); // Debug log (truncated for brevity)
          consolidatedLogs[studentRollNumber] = {
            'studentRollNumber': studentRollNumber,
            'attendanceTime': log['timestamp'],
            'photoData': photoData, // Changed from photoPath to photoData
          };
        }
      }
    }

    setState(() {
      _filteredAttendanceLogs = consolidatedLogs.values.toList();
    });
  }

  Future<String?> _fetchStudentPhoto(String rollNumber) async {
    final user = await mongo.MongoDBService.getUserByRollNumber(rollNumber);
    return user?['photoData']; // Changed from photoPath to photoData
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Faculty Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.shade100, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Create Feedback Form"),
              const SizedBox(height: 20),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'Form Title',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter form title';
                            }
                            return null;
                          },
                          onSaved: (value) => _formTitle = value!,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          label: 'Question 1',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter question 1';
                            }
                            return null;
                          },
                          onSaved: (value) => _question1 = value!,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          label: 'Question 2',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter question 2';
                            }
                            return null;
                          },
                          onSaved: (value) => _question2 = value!,
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : _buildElevatedButton(
                                onPressed: _createFeedbackForm,
                                label: "Create Form",
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle("Your Feedback Forms"),
              const SizedBox(height: 20),
              _feedbackForms.isEmpty
                  ? _buildEmptyMessage("No feedback forms created")
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _feedbackForms.length,
                      itemBuilder: (context, index) {
                        final form = _feedbackForms[index];
                        final formId = form['_id'].toHexString();
                        final responses = _responses[formId] ?? [];
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Title: ${form['title']}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Question 1: ${form['questions'][0]}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Question 2: ${form['questions'][1]}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 10),
                                _buildElevatedButton(
                                  onPressed: () => _viewResponses(formId),
                                  label: "View Responses",
                                ),
                                if (responses.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Responses:",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  ...responses.map((response) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Student Roll: ${response['studentRollNumber']}",
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              "Rating: ${response['rating']}",
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              "Comments: ${response['comments']}",
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const Divider(),
                                          ],
                                        ),
                                      )),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 30),
              _buildSectionTitle("Take Attendance"),
              const SizedBox(height: 20),
              _buildElevatedButton(
                onPressed: () {
                  setState(() {
                    _isScanning = !_isScanning;
                  });
                  if (!_isScanning) {
                    controller?.stopCamera();
                  }
                },
                label: _isScanning ? "Stop Scanning" : "Start Scanning",
                color: _isScanning ? Colors.red : Colors.blueAccent,
              ),
              if (_isScanning) ...[
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.blueAccent,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 250,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_scannedUser != null)
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          Text(
                            "Student: ${_scannedUser!['rollNumber']}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          _buildElevatedButton(
                            onPressed: _markAttendance,
                            label: "Mark Present",
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 30),
              _buildSectionTitle("Attendance Logs"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate == null
                        ? "Select a date to view logs"
                        : "Logs for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  _buildElevatedButton(
                    onPressed: () => _selectDate(context),
                    label: "Pick Date",
                    color: Colors.blueAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _selectedDate == null
                  ? _buildEmptyMessage("Please select a date to view logs")
                  : _filteredAttendanceLogs.isEmpty
                      ? _buildEmptyMessage("No attendance logs for this date")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredAttendanceLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredAttendanceLogs[index];
                            return Card(
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: log['photoData'] != null
                                          ? MemoryImage(base64Decode(log['photoData']))
                                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                      backgroundColor: Colors.grey.shade200,
                                      onBackgroundImageError: (exception, stackTrace) {
                                        print('Error loading image for ${log['studentRollNumber']}: $exception');
                                      },
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Student: ${log['studentRollNumber']}",
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "Marked At: ${log['attendanceTime'] != null ? log['attendanceTime'].substring(11, 16) : 'N/A'}",
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: const Icon(Icons.edit, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required String label,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
// import 'package:smart_campus_access/screens/login_screen.dart';
// import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;

// class FacultyScreen extends StatefulWidget {
//   final Map<String, dynamic> user;

//   const FacultyScreen({Key? key, required this.user}) : super(key: key);

//   @override
//   State<FacultyScreen> createState() => _FacultyScreenState();
// }

// class _FacultyScreenState extends State<FacultyScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   String _formTitle = '';
//   String _question1 = '';
//   String _question2 = '';
//   bool _isLoading = false;
//   bool _isScanning = false;
//   List<Map<String, dynamic>> _feedbackForms = [];
//   Map<String, List<Map<String, dynamic>>> _responses = {};
//   List<Map<String, dynamic>> _attendanceLogs = [];
//   QRViewController? controller;
//   String? scannedQrCode;
//   Map<String, dynamic>? _scannedUser;

//   @override
//   void initState() {
//     super.initState();
//     _fetchFeedbackForms();
//     _fetchAttendanceLogs();
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchFeedbackForms() async {
//     final forms = await mongo.MongoDBService.getFeedbackFormsByFaculty(widget.user['rollNumber']);
//     setState(() {
//       _feedbackForms = forms;
//     });
//   }

//   Future<void> _fetchAttendanceLogs() async {
//     final logs = await mongo.MongoDBService.getAttendanceLogsByFaculty(widget.user['rollNumber']);
//     setState(() {
//       _attendanceLogs = logs;
//     });
//   }

//   Future<void> _createFeedbackForm() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//       setState(() => _isLoading = true);

//       final form = {
//         'title': _formTitle,
//         'facultyRollNumber': widget.user['rollNumber'],
//         'questions': [
//           _question1,
//           _question2,
//         ],
//         'createdAt': DateTime.now().toIso8601String(),
//       };

//       await mongo.MongoDBService.createFeedbackForm(form);
//       setState(() => _isLoading = false);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Feedback form created successfully")),
//       );

//       _formKey.currentState!.reset();
//       _fetchFeedbackForms();
//     }
//   }

//   Future<void> _viewResponses(String formId) async {
//     final responses = await mongo.MongoDBService.getFeedbackResponsesByFormId(formId);
//     setState(() {
//       _responses[formId] = responses;
//     });
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;
//     controller.scannedDataStream.listen((scanData) async {
//       if (scanData.code != null) {
//         setState(() {
//           scannedQrCode = scanData.code;
//         });
//         final user = await mongo.MongoDBService.getUserByQrCodeId(scanData.code!);
//         if (user != null && user['role'] == 'student') {
//           setState(() {
//             _scannedUser = user;
//           });
//           controller.pauseCamera();
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Invalid QR code or user not a student")),
//           );
//         }
//       }
//     });
//   }

//   Future<void> _markAttendance() async {
//     if (_scannedUser == null || scannedQrCode == null) return;

//     final attendance = {
//       'studentRollNumber': _scannedUser!['rollNumber'],
//       'facultyRollNumber': widget.user['rollNumber'],
//       'timestamp': DateTime.now().toIso8601String(),
//     };

//     await mongo.MongoDBService.logAttendance(attendance);

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Attendance marked for ${_scannedUser!['rollNumber']}")),
//     );

//     setState(() {
//       _scannedUser = null;
//       scannedQrCode = null;
//     });

//     controller?.resumeCamera();
//     _fetchAttendanceLogs();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Faculty Dashboard",
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         backgroundColor: Colors.blueAccent,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LoginScreen()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blueAccent.shade100, Colors.white],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSectionTitle("Create Feedback Form"),
//               const SizedBox(height: 20),
//               Card(
//                 elevation: 8,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       children: [
//                         _buildTextField(
//                           label: 'Form Title',
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter form title';
//                             }
//                             return null;
//                           },
//                           onSaved: (value) => _formTitle = value!,
//                         ),
//                         const SizedBox(height: 15),
//                         _buildTextField(
//                           label: 'Question 1',
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter question 1';
//                             }
//                             return null;
//                           },
//                           onSaved: (value) => _question1 = value!,
//                         ),
//                         const SizedBox(height: 15),
//                         _buildTextField(
//                           label: 'Question 2',
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter question 2';
//                             }
//                             return null;
//                           },
//                           onSaved: (value) => _question2 = value!,
//                         ),
//                         const SizedBox(height: 20),
//                         _isLoading
//                             ? const CircularProgressIndicator()
//                             : _buildElevatedButton(
//                                 onPressed: _createFeedbackForm,
//                                 label: "Create Form",
//                               ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Your Feedback Forms"),
//               const SizedBox(height: 20),
//               _feedbackForms.isEmpty
//                   ? _buildEmptyMessage("No feedback forms created")
//                   : ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: _feedbackForms.length,
//                       itemBuilder: (context, index) {
//                         final form = _feedbackForms[index];
//                         final formId = form['_id'].toHexString();
//                         final responses = _responses[formId] ?? [];
//                         return Card(
//                           elevation: 5,
//                           margin: const EdgeInsets.symmetric(vertical: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(15),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Title: ${form['title']}",
//                                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 Text(
//                                   "Question 1: ${form['questions'][0]}",
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Text(
//                                   "Question 2: ${form['questions'][1]}",
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 _buildElevatedButton(
//                                   onPressed: () => _viewResponses(formId),
//                                   label: "View Responses",
//                                 ),
//                                 if (responses.isNotEmpty) ...[
//                                   const SizedBox(height: 10),
//                                   const Text(
//                                     "Responses:",
//                                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                                   ),
//                                   ...responses.map((response) => Padding(
//                                         padding: const EdgeInsets.symmetric(vertical: 5),
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               "Student Roll: ${response['studentRollNumber']}",
//                                               style: const TextStyle(fontSize: 14),
//                                             ),
//                                             Text(
//                                               "Rating: ${response['rating']}",
//                                               style: const TextStyle(fontSize: 14),
//                                             ),
//                                             Text(
//                                               "Comments: ${response['comments']}",
//                                               style: const TextStyle(fontSize: 14),
//                                             ),
//                                             const Divider(),
//                                           ],
//                                         ),
//                                       )),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Take Attendance"),
//               const SizedBox(height: 20),
//               _buildElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _isScanning = !_isScanning;
//                   });
//                   if (!_isScanning) {
//                     controller?.stopCamera();
//                   }
//                 },
//                 label: _isScanning ? "Stop Scanning" : "Start Scanning",
//                 color: _isScanning ? Colors.red : Colors.blueAccent,
//               ),
//               if (_isScanning) ...[
//                 const SizedBox(height: 20),
//                 Container(
//                   height: 300,
//                   margin: const EdgeInsets.symmetric(horizontal: 20),
//                   child: QRView(
//                     key: qrKey,
//                     onQRViewCreated: _onQRViewCreated,
//                     overlay: QrScannerOverlayShape(
//                       borderColor: Colors.blueAccent,
//                       borderRadius: 10,
//                       borderLength: 30,
//                       borderWidth: 10,
//                       cutOutSize: 250,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 if (_scannedUser != null)
//                   Card(
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(15),
//                       child: Column(
//                         children: [
//                           Text(
//                             "Student: ${_scannedUser!['rollNumber']}",
//                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 20),
//                           _buildElevatedButton(
//                             onPressed: _markAttendance,
//                             label: "Mark Present",
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//               const SizedBox(height: 30),
//               _buildSectionTitle("Attendance Logs"),
//               const SizedBox(height: 20),
//               _attendanceLogs.isEmpty
//                   ? _buildEmptyMessage("No attendance logs available")
//                   : ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: _attendanceLogs.length,
//                       itemBuilder: (context, index) {
//                         final log = _attendanceLogs[index];
//                         return Card(
//                           elevation: 5,
//                           margin: const EdgeInsets.symmetric(vertical: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(15),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Student Roll: ${log['studentRollNumber']}",
//                                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Text(
//                                   "Timestamp: ${log['timestamp']}",
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 24,
//         fontWeight: FontWeight.bold,
//         color: Colors.blueAccent,
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required String? Function(String?) validator,
//     required void Function(String?) onSaved,
//   }) {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.edit, color: Colors.blueAccent),
//         filled: true,
//         fillColor: Colors.white,
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
//         ),
//       ),
//       validator: validator,
//       onSaved: onSaved,
//     );
//   }

//   Widget _buildElevatedButton({
//     required VoidCallback onPressed,
//     required String label,
//     Color? color,
//   }) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color ?? Colors.blueAccent,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         elevation: 5,
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(fontSize: 16, color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyMessage(String message) {
//     return Center(
//       child: Text(
//         message,
//         style: const TextStyle(fontSize: 16, color: Colors.grey),
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
// import 'package:smart_campus_access/screens/login_screen.dart';
// import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;

// class FacultyScreen extends StatefulWidget {
//   final Map<String, dynamic> user;

//   const FacultyScreen({Key? key, required this.user}) : super(key: key);

//   @override
//   State<FacultyScreen> createState() => _FacultyScreenState();
// }

// class _FacultyScreenState extends State<FacultyScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   String _formTitle = '';
//   String _question1 = '';
//   String _question2 = '';
//   bool _isLoading = false;
//   bool _isScanning = false;
//   List<Map<String, dynamic>> _feedbackForms = [];
//   Map<String, List<Map<String, dynamic>>> _responses = {};
//   List<Map<String, dynamic>> _attendanceLogs = [];
//   DateTime? _selectedDate;
//   List<Map<String, dynamic>> _filteredAttendanceLogs = [];
//   QRViewController? controller;
//   String? scannedQrCode;
//   Map<String, dynamic>? _scannedUser;

//   @override
//   void initState() {
//     super.initState();
//     _fetchFeedbackForms();
//     _fetchAttendanceLogs();
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchFeedbackForms() async {
//     final forms = await mongo.MongoDBService.getFeedbackFormsByFaculty(widget.user['rollNumber']);
//     setState(() {
//       _feedbackForms = forms;
//     });
//   }

//   Future<void> _fetchAttendanceLogs() async {
//     final logs = await mongo.MongoDBService.getAttendanceLogsByFaculty(widget.user['rollNumber']);
//     setState(() {
//       _attendanceLogs = logs;
//       if (_selectedDate != null) {
//         _filterAttendanceLogsByDate();
//       }
//     });
//   }

//   Future<void> _createFeedbackForm() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//       setState(() => _isLoading = true);

//       final form = {
//         'title': _formTitle,
//         'facultyRollNumber': widget.user['rollNumber'],
//         'questions': [
//           _question1,
//           _question2,
//         ],
//         'createdAt': DateTime.now().toIso8601String(),
//       };

//       await mongo.MongoDBService.createFeedbackForm(form);
//       setState(() => _isLoading = false);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Feedback form created successfully")),
//       );

//       _formKey.currentState!.reset();
//       _fetchFeedbackForms();
//     }
//   }

//   Future<void> _viewResponses(String formId) async {
//     final responses = await mongo.MongoDBService.getFeedbackResponsesByFormId(formId);
//     setState(() {
//       _responses[formId] = responses;
//     });
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;
//     controller.scannedDataStream.listen((scanData) async {
//       if (scanData.code != null) {
//         setState(() {
//           scannedQrCode = scanData.code;
//         });
//         final user = await mongo.MongoDBService.getUserByQrCodeId(scanData.code!);
//         if (user != null && user['role'] == 'student') {
//           setState(() {
//             _scannedUser = user;
//           });
//           controller.pauseCamera();
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Invalid QR code or user not a student")),
//           );
//         }
//       }
//     });
//   }

//   Future<void> _markAttendance() async {
//     if (_scannedUser == null || scannedQrCode == null) return;

//     final attendance = {
//       'studentRollNumber': _scannedUser!['rollNumber'],
//       'facultyRollNumber': widget.user['rollNumber'],
//       'timestamp': DateTime.now().toIso8601String(),
//     };

//     await mongo.MongoDBService.logAttendance(attendance);

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Attendance marked for ${_scannedUser!['rollNumber']}")),
//     );

//     setState(() {
//       _scannedUser = null;
//       scannedQrCode = null;
//     });

//     controller?.resumeCamera();
//     _fetchAttendanceLogs();
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2030),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _filterAttendanceLogsByDate();
//       });
//     }
//   }

//   void _filterAttendanceLogsByDate() {
//     if (_selectedDate == null) {
//       _filteredAttendanceLogs = [];
//       return;
//     }

//     final selectedDateStr = _selectedDate!.toIso8601String().substring(0, 10); // YYYY-MM-DD
//     final Map<String, Map<String, dynamic>> consolidatedLogs = {};

//     for (var log in _attendanceLogs) {
//       final logDate = log['timestamp'].substring(0, 10);
//       if (logDate == selectedDateStr) {
//         final studentRollNumber = log['studentRollNumber'];
//         if (!consolidatedLogs.containsKey(studentRollNumber)) {
//           consolidatedLogs[studentRollNumber] = {
//             'studentRollNumber': studentRollNumber,
//             'attendanceTime': log['timestamp'],
//             'photoPath': null,
//           };
//           _fetchStudentPhoto(studentRollNumber).then((photoPath) {
//             setState(() {
//               consolidatedLogs[studentRollNumber]!['photoPath'] = photoPath;
//             });
//           });
//         }
//       }
//     }

//     setState(() {
//       _filteredAttendanceLogs = consolidatedLogs.values.toList();
//     });
//   }

//   Future<String?> _fetchStudentPhoto(String rollNumber) async {
//     final user = await mongo.MongoDBService.getUserByRollNumber(rollNumber);
//     return user?['photoPath'];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Faculty Dashboard",
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         backgroundColor: Colors.blueAccent,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout, color: Colors.white),
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LoginScreen()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.blueAccent.shade100, Colors.white],
//           ),
//         ),
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSectionTitle("Create Feedback Form"),
//               const SizedBox(height: 20),
//               Card(
//                 elevation: 8,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       children: [
//                         _buildTextField(
//                           label: 'Form Title',
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter form title';
//                             }
//                             return null;
//                           },
//                           onSaved: (value) => _formTitle = value!,
//                         ),
//                         const SizedBox(height: 15),
//                         _buildTextField(
//                           label: 'Question 1',
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter question 1';
//                             }
//                             return null;
//                           },
//                           onSaved: (value) => _question1 = value!,
//                         ),
//                         const SizedBox(height: 15),
//                         _buildTextField(
//                           label: 'Question 2',
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter question 2';
//                             }
//                             return null;
//                           },
//                           onSaved: (value) => _question2 = value!,
//                         ),
//                         const SizedBox(height: 20),
//                         _isLoading
//                             ? const CircularProgressIndicator()
//                             : _buildElevatedButton(
//                                 onPressed: _createFeedbackForm,
//                                 label: "Create Form",
//                               ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Your Feedback Forms"),
//               const SizedBox(height: 20),
//               _feedbackForms.isEmpty
//                   ? _buildEmptyMessage("No feedback forms created")
//                   : ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: _feedbackForms.length,
//                       itemBuilder: (context, index) {
//                         final form = _feedbackForms[index];
//                         final formId = form['_id'].toHexString();
//                         final responses = _responses[formId] ?? [];
//                         return Card(
//                           elevation: 5,
//                           margin: const EdgeInsets.symmetric(vertical: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(15),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   "Title: ${form['title']}",
//                                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 Text(
//                                   "Question 1: ${form['questions'][0]}",
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                                 const SizedBox(height: 5),
//                                 Text(
//                                   "Question 2: ${form['questions'][1]}",
//                                   style: const TextStyle(fontSize: 14),
//                                 ),
//                                 const SizedBox(height: 10),
//                                 _buildElevatedButton(
//                                   onPressed: () => _viewResponses(formId),
//                                   label: "View Responses",
//                                 ),
//                                 if (responses.isNotEmpty) ...[
//                                   const SizedBox(height: 10),
//                                   const Text(
//                                     "Responses:",
//                                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                                   ),
//                                   ...responses.map((response) => Padding(
//                                         padding: const EdgeInsets.symmetric(vertical: 5),
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               "Student Roll: ${response['studentRollNumber']}",
//                                               style: const TextStyle(fontSize: 14),
//                                             ),
//                                             Text(
//                                               "Rating: ${response['rating']}",
//                                               style: const TextStyle(fontSize: 14),
//                                             ),
//                                             Text(
//                                               "Comments: ${response['comments']}",
//                                               style: const TextStyle(fontSize: 14),
//                                             ),
//                                             const Divider(),
//                                           ],
//                                         ),
//                                       )),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//               const SizedBox(height: 30),
//               _buildSectionTitle("Take Attendance"),
//               const SizedBox(height: 20),
//               _buildElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _isScanning = !_isScanning;
//                   });
//                   if (!_isScanning) {
//                     controller?.stopCamera();
//                   }
//                 },
//                 label: _isScanning ? "Stop Scanning" : "Start Scanning",
//                 color: _isScanning ? Colors.red : Colors.blueAccent,
//               ),
//               if (_isScanning) ...[
//                 const SizedBox(height: 20),
//                 Container(
//                   height: 300,
//                   margin: const EdgeInsets.symmetric(horizontal: 20),
//                   child: QRView(
//                     key: qrKey,
//                     onQRViewCreated: _onQRViewCreated,
//                     overlay: QrScannerOverlayShape(
//                       borderColor: Colors.blueAccent,
//                       borderRadius: 10,
//                       borderLength: 30,
//                       borderWidth: 10,
//                       cutOutSize: 250,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 if (_scannedUser != null)
//                   Card(
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(15),
//                       child: Column(
//                         children: [
//                           Text(
//                             "Student: ${_scannedUser!['rollNumber']}",
//                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 20),
//                           _buildElevatedButton(
//                             onPressed: _markAttendance,
//                             label: "Mark Present",
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//               const SizedBox(height: 30),
//               _buildSectionTitle("Attendance Logs"),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     _selectedDate == null
//                         ? "Select a date to view logs"
//                         : "Logs for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
//                     style: const TextStyle(fontSize: 16, color: Colors.black54),
//                   ),
//                   _buildElevatedButton(
//                     onPressed: () => _selectDate(context),
//                     label: "Pick Date",
//                     color: Colors.blueAccent,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               _selectedDate == null
//                   ? _buildEmptyMessage("Please select a date to view logs")
//                   : _filteredAttendanceLogs.isEmpty
//                       ? _buildEmptyMessage("No attendance logs for this date")
//                       : ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: _filteredAttendanceLogs.length,
//                           itemBuilder: (context, index) {
//                             final log = _filteredAttendanceLogs[index];
//                             return Card(
//                               elevation: 5,
//                               margin: const EdgeInsets.symmetric(vertical: 10),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(15),
//                                 child: Row(
//                                   children: [
//                                     CircleAvatar(
//                                       radius: 30,
//                                       backgroundImage: log['photoPath'] != null
//                                           ? NetworkImage(log['photoPath'])
//                                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                                       backgroundColor: Colors.grey.shade200,
//                                     ),
//                                     const SizedBox(width: 15),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             "Student: ${log['studentRollNumber']}",
//                                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                                           ),
//                                           const SizedBox(height: 5),
//                                           Text(
//                                             "Marked At: ${log['attendanceTime'] != null ? log['attendanceTime'].substring(11, 16) : 'N/A'}",
//                                             style: const TextStyle(fontSize: 14),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 24,
//         fontWeight: FontWeight.bold,
//         color: Colors.blueAccent,
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String label,
//     required String? Function(String?) validator,
//     required void Function(String?) onSaved,
//   }) {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: const Icon(Icons.edit, color: Colors.blueAccent),
//         filled: true,
//         fillColor: Colors.white,
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
//         ),
//       ),
//       validator: validator,
//       onSaved: onSaved,
//     );
//   }

//   Widget _buildElevatedButton({
//     required VoidCallback onPressed,
//     required String label,
//     Color? color,
//   }) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color ?? Colors.blueAccent,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         elevation: 5,
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(fontSize: 16, color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildEmptyMessage(String message) {
//     return Center(
//       child: Text(
//         message,
//         style: const TextStyle(fontSize: 16, color: Colors.grey),
//       ),
//     );
//   }
// }
