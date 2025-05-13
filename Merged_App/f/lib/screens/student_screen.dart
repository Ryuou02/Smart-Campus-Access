// import 'package:flutter/material.dart';
// import 'package:smart_campus_access/screens/login_screen.dart';
// import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;
// import 'package:smart_campus_access/widgets/id_card_widget.dart';

// class StudentScreen extends StatefulWidget {
//   final Map<String, dynamic> user;

//   const StudentScreen({Key? key, required this.user}) : super(key: key);

//   @override
//   State<StudentScreen> createState() => _StudentScreenState();
// }

// class _StudentScreenState extends State<StudentScreen> {
//   bool _isEditing = false;
//   bool _isFillingFeedback = false;
//   Map<String, dynamic>? _selectedForm;
//   final _formKey = GlobalKey<FormState>();
//   final _feedbackFormKey = GlobalKey<FormState>();
//   late String _name;
//   late String _phoneNumber;
//   late String _rollNumber;
//   late String _year;
//   late String _degree;
//   late String _specialization;
//   late String? _photoData; // Changed to photoData
//   late String _qrCodeId;
//   double _rating = 3.0;
//   String _comments = '';
//   List<Map<String, dynamic>> _feedbackForms = [];

//   @override
//   void initState() {
//     super.initState();
//     _name = widget.user['name'] ?? 'N/A';
//     _phoneNumber = widget.user['phoneNumber'] ?? 'N/A';
//     _rollNumber = widget.user['rollNumber'] ?? 'N/A';
//     _year = widget.user['year'] ?? 'N/A';
//     _degree = widget.user['degree'] ?? 'N/A';
//     _specialization = widget.user['specialization'] ?? 'N/A';
//     _photoData = widget.user['photoData']; // Changed to photoData
//     _qrCodeId = widget.user['qrCodeId'] ?? '';
//     _fetchFeedbackForms();
//   }

//   Future<void> _fetchFeedbackForms() async {
//     final forms = await mongo.MongoDBService.getAllFeedbackForms();
//     setState(() {
//       _feedbackForms = forms;
//     });
//   }

//   Future<void> _submitRequest() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();

//       final updatedFields = {
//         'name': _name,
//         'phoneNumber': _phoneNumber,
//         'year': _year,
//         'degree': _degree,
//         'specialization': _specialization,
//       };

//       final request = {
//         'studentRollNumber': _rollNumber,
//         'updatedFields': updatedFields,
//         'status': 'pending',
//         'createdAt': DateTime.now().toIso8601String(),
//       };

//       await mongo.MongoDBService.createRequest(request);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Profile update request sent to admin")),
//       );

//       setState(() {
//         _isEditing = false;
//       });
//     }
//   }

//   Future<void> _submitFeedback() async {
//     if (_feedbackFormKey.currentState!.validate()) {
//       _feedbackFormKey.currentState!.save();

//       final response = {
//         'formId': _selectedForm!['_id'].toHexString(),
//         'studentRollNumber': _rollNumber,
//         'rating': _rating,
//         'comments': _comments,
//         'submittedAt': DateTime.now().toIso8601String(),
//       };

//       await mongo.MongoDBService.submitFeedbackResponse(response);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Feedback submitted successfully")),
//       );

//       setState(() {
//         _isFillingFeedback = false;
//         _selectedForm = null;
//         _rating = 3.0;
//         _comments = '';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Student Dashboard",
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
//         child: _isEditing
//             ? _buildEditForm()
//             : _isFillingFeedback
//                 ? _buildFeedbackForm()
//                 : SingleChildScrollView(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (widget.user['photoData'] == null) // Changed to photoData
//                           _buildEmptyMessage("ID card not yet generated. Please contact admin.")
//                         else
//                           IdCardWidget(
//                             name: widget.user['name'] ?? 'N/A',
//                             rollNumber: widget.user['rollNumber'] ?? 'N/A',
//                             phoneNumber: widget.user['phoneNumber'] ?? 'N/A',
//                             year: widget.user['year'],
//                             degree: widget.user['degree'],
//                             specialization: widget.user['specialization'],
//                             photoData: widget.user['photoData'], // Changed to photoData
//                             qrCodeId: _qrCodeId,
//                             onReset: () {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const LoginScreen()),
//                               );
//                             },
//                           ),
//                         const SizedBox(height: 20),
//                         _buildElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               _isEditing = true;
//                             });
//                           },
//                           label: "Edit Profile",
//                         ),
//                         const SizedBox(height: 30),
//                         _buildSectionTitle("Available Feedback Forms"),
//                         const SizedBox(height: 20),
//                         _feedbackForms.isEmpty
//                             ? _buildEmptyMessage("No feedback forms available")
//                             : ListView.builder(
//                                 shrinkWrap: true,
//                                 physics: const NeverScrollableScrollPhysics(),
//                                 itemCount: _feedbackForms.length,
//                                 itemBuilder: (context, index) {
//                                   final form = _feedbackForms[index];
//                                   return Card(
//                                     elevation: 5,
//                                     margin: const EdgeInsets.symmetric(vertical: 10),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(15),
//                                     ),
//                                     child: Padding(
//                                       padding: const EdgeInsets.all(15),
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             "Title: ${form['title']}",
//                                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                                           ),
//                                           const SizedBox(height: 10),
//                                           Text(
//                                             "Question 1: ${form['questions'][0]}",
//                                             style: const TextStyle(fontSize: 14),
//                                           ),
//                                           const SizedBox(height: 5),
//                                           Text(
//                                             "Question 2: ${form['questions'][1]}",
//                                             style: const TextStyle(fontSize: 14),
//                                           ),
//                                           const SizedBox(height: 10),
//                                           _buildElevatedButton(
//                                             onPressed: () {
//                                               setState(() {
//                                                 _isFillingFeedback = true;
//                                                 _selectedForm = form;
//                                               });
//                                             },
//                                             label: "Fill Form",
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ],
//                     ),
//                   ),
//       ),
//     );
//   }

//   Widget _buildEditForm() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             _buildTextField(
//               label: 'Name',
//               initialValue: _name,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your name';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _name = value!,
//             ),
//             const SizedBox(height: 15),
//             _buildTextField(
//               label: 'Phone Number',
//               initialValue: _phoneNumber,
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
//             _buildTextField(
//               label: 'Year',
//               initialValue: _year,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your year';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _year = value!,
//             ),
//             const SizedBox(height: 15),
//             _buildTextField(
//               label: 'Degree',
//               initialValue: _degree,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your degree';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _degree = value!,
//             ),
//             const SizedBox(height: 15),
//             _buildTextField(
//               label: 'Specialization',
//               initialValue: _specialization,
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
//                 _buildElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _isEditing = false;
//                     });
//                   },
//                   label: "Cancel",
//                   color: Colors.grey,
//                 ),
//                 _buildElevatedButton(
//                   onPressed: _submitRequest,
//                   label: "Submit Request",
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFeedbackForm() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Form(
//         key: _feedbackFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Feedback Form: ${_selectedForm!['title']}",
//               style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               "Question 1: ${_selectedForm!['questions'][0]}",
//               style: const TextStyle(fontSize: 14),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               "Question 2: ${_selectedForm!['questions'][1]}",
//               style: const TextStyle(fontSize: 14),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Rating (1-5):",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//             Slider(
//               value: _rating,
//               min: 1,
//               max: 5,
//               divisions: 4,
//               label: _rating.round().toString(),
//               onChanged: (value) {
//                 setState(() {
//                   _rating = value;
//                 });
//               },
//               activeColor: Colors.blueAccent,
//             ),
//             const SizedBox(height: 15),
//             _buildTextField(
//               label: 'Comments',
//               maxLines: 3,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your comments';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _comments = value!,
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _isFillingFeedback = false;
//                       _selectedForm = null;
//                     });
//                   },
//                   label: "Cancel",
//                   color: Colors.grey,
//                 ),
//                 _buildElevatedButton(
//                   onPressed: _submitFeedback,
//                   label: "Submit Feedback",
//                 ),
//               ],
//             ),
//           ],
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
//     String? initialValue,
//     bool obscureText = false,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//     required String? Function(String?) validator,
//     required void Function(String?) onSaved,
//   }) {
//     return TextFormField(
//       initialValue: initialValue,
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
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       maxLines: maxLines,
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



import 'package:flutter/material.dart';
import 'package:smart_campus_access/screens/login_screen.dart';
import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;
import 'package:smart_campus_access/widgets/id_card_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const StudentScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  bool _isEditing = false;
  bool _isFillingFeedback = false;
  bool _isFetchingCourses = false;
  Map<String, dynamic>? _selectedForm;
  final _formKey = GlobalKey<FormState>();
  final _feedbackFormKey = GlobalKey<FormState>();
  late String _name;
  late String _phoneNumber;
  late String _rollNumber;
  late String _year;
  late String _degree;
  late String _specialization;
  late String? _photoData;
  late String _qrCodeId;
  double _rating = 3.0;
  String _comments = '';
  List<Map<String, dynamic>> _feedbackForms = [];
  List<Map<String, dynamic>> _courses = [];
  Set<String> _loadingLinks = {};

  @override
  void initState() {
    super.initState();
    _name = widget.user['name'] ?? 'N/A';
    _phoneNumber = widget.user['phoneNumber'] ?? 'N/A';
    _rollNumber = widget.user['rollNumber'] ?? 'N/A';
    _year = widget.user['year'] ?? 'N/A';
    _degree = widget.user['degree'] ?? 'N/A';
    _specialization = widget.user['specialization'] ?? 'N/A';
    _photoData = widget.user['photoData'];
    _qrCodeId = widget.user['qrCodeId'] ?? '';
    _fetchFeedbackForms();
    _fetchCourses();
  }

  Future<void> _fetchFeedbackForms() async {
    final forms = await mongo.MongoDBService.getAllFeedbackForms();
    setState(() {
      _feedbackForms = forms;
    });
  }

  Future<void> _fetchCourses() async {
    try {
      setState(() {
        _isFetchingCourses = true;
      });
      final courses = await mongo.MongoDBService.getCoursesForStudent(_rollNumber);
      setState(() {
        _courses = courses;
      });
    } catch (e) {
      print("Error fetching courses for student $_rollNumber: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching courses: $e")),
      );
    } finally {
      setState(() {
        _isFetchingCourses = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedFields = {
        'name': _name,
        'phoneNumber': _phoneNumber,
        'year': _year,
        'degree': _degree,
        'specialization': _specialization,
      };

      final request = {
        'studentRollNumber': _rollNumber,
        'updatedFields': updatedFields,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await mongo.MongoDBService.createRequest(request);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile update request sent to admin")),
      );

      // Refresh courses in case the update affects course assignments
      await _fetchCourses();

      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackFormKey.currentState!.validate()) {
      _feedbackFormKey.currentState!.save();

      final response = {
        'formId': _selectedForm!['_id'].toHexString(),
        'studentRollNumber': _rollNumber,
        'rating': _rating,
        'comments': _comments,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      await mongo.MongoDBService.submitFeedbackResponse(response);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully")),
      );

      setState(() {
        _isFillingFeedback = false;
        _selectedForm = null;
        _rating = 3.0;
        _comments = '';
      });
    }
  }

  Future<void> _launchURL(String url) async {
    // Validate the URL format
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final Uri uri = Uri.tryParse(url) ?? Uri();
    if (uri.scheme.isEmpty || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid URL: $url")),
      );
      return;
    }

    // Add the URL to the loading set
    setState(() {
      _loadingLinks.add(url);
    });

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No app available to open $url")),
        );
      }
    } catch (e) { 
      print("Error launching URL $url: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open $url: $e")),
      );
    } finally {
      // Remove the URL from the loading set
      setState(() {
        _loadingLinks.remove(url);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
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
        child: _isEditing
            ? _buildEditForm()
            : _isFillingFeedback
                ? _buildFeedbackForm()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.user['photoData'] == null)
                          _buildEmptyMessage("ID card not yet generated. Please contact admin.")
                        else
                          IdCardWidget(
                            name: widget.user['name'] ?? 'N/A',
                            rollNumber: widget.user['rollNumber'] ?? 'N/A',
                            phoneNumber: widget.user['phoneNumber'] ?? 'N/A',
                            year: widget.user['year'],
                            degree: widget.user['degree'],
                            specialization: widget.user['specialization'],
                            photoData: widget.user['photoData'],
                            qrCodeId: _qrCodeId,
                            onReset: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                        _buildElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          label: "Edit Profile",
                        ),
                        const SizedBox(height: 30),
                        _buildSectionTitle("Available Feedback Forms"),
                        const SizedBox(height: 20),
                        _feedbackForms.isEmpty
                            ? _buildEmptyMessage("No feedback forms available")
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _feedbackForms.length,
                                itemBuilder: (context, index) {
                                  final form = _feedbackForms[index];
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
                                            onPressed: () {
                                              setState(() {
                                                _isFillingFeedback = true;
                                                _selectedForm = form;
                                              });
                                            },
                                            label: "Fill Form",
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 30),
                        _buildSectionTitle("My Courses"),
                        const SizedBox(height: 20),
                        _isFetchingCourses
                            ? const Center(child: CircularProgressIndicator())
                            : _courses.isEmpty
                                ? _buildEmptyMessage("No courses assigned yet")
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _courses.length,
                                    itemBuilder: (context, index) {
                                      final course = _courses[index];
                                      final resources = course['resources'] as Map<String, dynamic>;
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
                                                "Course: ${course['courseName']}",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(height: 5),
                                              Text("Code: ${course['courseCode']}"),
                                              const SizedBox(height: 10),
                                              _buildResourceLink(
                                                "View Full Syllabus",
                                                resources['syllabusLink'] as String? ?? '',
                                              ),
                                              const SizedBox(height: 5),
                                              _buildResourceLink(
                                                "Class Schedule",
                                                resources['scheduleLink'] as String? ?? '',
                                              ),
                                              const SizedBox(height: 5),
                                              _buildResourceLink(
                                                "Additional Materials",
                                                resources['materialsLink'] as String? ?? '',
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

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              label: 'Name',
              initialValue: _name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Phone Number',
              initialValue: _phoneNumber,
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
            _buildTextField(
              label: 'Year',
              initialValue: _year,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your year';
                }
                return null;
              },
              onSaved: (value) => _year = value!,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Degree',
              initialValue: _degree,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your degree';
                }
                return null;
              },
              onSaved: (value) => _degree = value!,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Specialization',
              initialValue: _specialization,
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
                _buildElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                  },
                  label: "Cancel",
                  color: Colors.grey,
                ),
                _buildElevatedButton(
                  onPressed: _submitRequest,
                  label: "Submit Request",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _feedbackFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Feedback Form: ${_selectedForm!['title']}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            Text(
              "Question 1: ${_selectedForm!['questions'][0]}",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              "Question 2: ${_selectedForm!['questions'][1]}",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              "Rating (1-5):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.round().toString(),
              onChanged: (value) {
                setState(() {
                  _rating = value;
                });
              },
              activeColor: Colors.blueAccent,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Comments',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your comments';
                }
                return null;
              },
              onSaved: (value) => _comments = value!,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isFillingFeedback = false;
                      _selectedForm = null;
                    });
                  },
                  label: "Cancel",
                  color: Colors.grey,
                ),
                _buildElevatedButton(
                  onPressed: _submitFeedback,
                  label: "Submit Feedback",
                ),
              ],
            ),
          ],
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
    String? initialValue,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
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
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Widget _buildResourceLink(String label, String url) {
    if (url.isEmpty) {
      return Text(
        "$label: Not Available",
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      );
    }
    final isLoading = _loadingLinks.contains(url);
    return InkWell(
      onTap: isLoading ? null : () => _launchURL(url),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isLoading ? Colors.grey : Colors.blue,
              decoration: isLoading ? TextDecoration.none : TextDecoration.underline,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(width: 5),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}