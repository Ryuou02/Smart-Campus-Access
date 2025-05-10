import 'package:flutter/material.dart';
import 'package:smart_campus_access/models/user.dart';
import 'package:smart_campus_access/screens/login_screen.dart';
import 'package:smart_campus_access/screens/recognition_screen.dart';
import 'package:smart_campus_access/screens/registration_screen.dart';
import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;
import 'package:smart_campus_access/widgets/id_card_widget.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;
import 'dart:convert';

class AdminScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackFormKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _rollNumber = '';
  String _name = '';
  String _role = 'student';
  String _title = '';
  String _question1 = '';
  String _question2 = '';
  bool _isLoading = false;
  bool _isCreatingForm = false;
  bool _isViewingStudents = false;
  bool _isViewingFeedback = false;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _feedbackForms = [];
  List<Map<String, dynamic>> _feedbackResponses = [];
  List<Map<String, dynamic>> _accessLogs = [];
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _filteredLogs = [];
  Map<String, dynamic>? _selectedStudent;
  Map<String, bool> _isGeneratingId = {}; // Track which student's ID is being generated

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
    _fetchStudents();
    _fetchFeedbackForms();
    _fetchFeedbackResponses();
    _fetchAccessLogs();
  }

  Future<void> _fetchPendingRequests() async {
    final requests = await mongo.MongoDBService.getPendingRequests();
    setState(() {
      _pendingRequests = requests;
    });
  }

  Future<void> _fetchStudents() async {
    final students = await mongo.MongoDBService.getAllStudents();
    setState(() {
      _students = students;
      // Initialize the loading state for each student
      for (var student in students) {
        _isGeneratingId[student['rollNumber']] = false;
      }
    });
  }

  Future<void> _fetchFeedbackForms() async {
    final forms = await mongo.MongoDBService.getAllFeedbackForms();
    setState(() {
      _feedbackForms = forms;
    });
  }

  Future<void> _fetchFeedbackResponses() async {
    final responses = await mongo.MongoDBService.getAllFeedbackResponses();
    setState(() {
      _feedbackResponses = responses;
    });
  }

  Future<void> _fetchAccessLogs() async {
    final logs = await mongo.MongoDBService.getAccessLogs();
    setState(() {
      _accessLogs = logs;
      if (_selectedDate != null) {
        _filterLogsByDate();
      }
    });
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      final existingUser = await mongo.MongoDBService.getUserByRollNumber(_rollNumber);
      if (existingUser != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A user with this roll number already exists.")),
        );
        return;
      }

      final user = User(
        email: _email,
        password: _password,
        role: _role,
        rollNumber: _rollNumber,
        name: _role != 'student' ? _name : null,
      ).toMap();

      await mongo.MongoDBService.insertUser(user);
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User registered successfully")),
      );

      _formKey.currentState!.reset();
    }
  }

  Future<void> _createFeedbackForm() async {
    if (_feedbackFormKey.currentState!.validate()) {
      _feedbackFormKey.currentState!.save();

      final feedbackForm = {
        'title': _title,
        'questions': [_question1, _question2],
        'createdAt': DateTime.now().toIso8601String(),
      };

      await mongo.MongoDBService.createFeedbackForm(feedbackForm);
      await _fetchFeedbackForms();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback form created successfully")),
      );

      setState(() {
        _isCreatingForm = false;
        _title = '';
        _question1 = '';
        _question2 = '';
      });
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final rollNumber = request['studentRollNumber'];
    final updatedFields = request['updatedFields'] as Map<String, dynamic>;

    final student = await mongo.MongoDBService.getUserByRollNumber(rollNumber);
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student not found")),
      );
      return;
    }

    final updatedUser = {
      'name': updatedFields['name'] ?? student['name'] ?? 'N/A',
      'phoneNumber': updatedFields['phoneNumber'] ?? student['phoneNumber'] ?? 'N/A',
      'year': updatedFields['year'] ?? student['year'] ?? 'N/A',
      'degree': updatedFields['degree'] ?? student['degree'] ?? 'N/A',
      'specialization': updatedFields['specialization'] ?? student['specialization'] ?? 'N/A',
    };

    await mongo.MongoDBService.updateUserByRollNumber(rollNumber, updatedUser);
    final requestId = request['_id'] as mongo_dart.ObjectId;
    await mongo.MongoDBService.updateRequestStatus(requestId, 'approved');
    await _fetchPendingRequests();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request approved and user updated")),
    );
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final requestId = request['_id'] as mongo_dart.ObjectId;
    await mongo.MongoDBService.updateRequestStatus(requestId, 'rejected');
    await _fetchPendingRequests();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Request rejected")),
    );
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
        _filterLogsByDate();
      });
    }
  }

  void _filterLogsByDate() {
    if (_selectedDate == null) {
      _filteredLogs = [];
      return;
    }

    final selectedDateStr = _selectedDate!.toIso8601String().substring(0, 10);
    final Map<String, Map<String, dynamic>> consolidatedLogs = {};

    for (var log in _accessLogs) {
      final logDate = log['timestamp'].substring(0, 10);
      if (logDate == selectedDateStr) {
        final studentRollNumber = log['studentRollNumber'];
        if (!consolidatedLogs.containsKey(studentRollNumber)) {
          consolidatedLogs[studentRollNumber] = {
            'studentRollNumber': studentRollNumber,
            'entryTime': null,
            'exitTime': null,
            'photoData': null,
          };
          _fetchStudentPhoto(studentRollNumber).then((photoData) {
            setState(() {
              consolidatedLogs[studentRollNumber]!['photoData'] = photoData;
            });
          });
        }
        if (log['action'] == 'entry') {
          consolidatedLogs[studentRollNumber]!['entryTime'] = log['timestamp'];
        } else if (log['action'] == 'exit') {
          consolidatedLogs[studentRollNumber]!['exitTime'] = log['timestamp'];
        }
      }
    }

    setState(() {
      _filteredLogs = consolidatedLogs.values.toList();
    });
  }

  Future<String?> _fetchStudentPhoto(String rollNumber) async {
    final user = await mongo.MongoDBService.getUserByRollNumber(rollNumber);
    return user?['photoData'];
  }

  Future<void> _generateId(String rollNumber) async {
    setState(() {
      _isGeneratingId[rollNumber] = true;
    });

    // Simulate ID generation process (replace this with actual ID generation logic)
    await Future.delayed(const Duration(seconds: 2));

    // For demonstration, we'll assume the ID generation sets photoData
    // In a real app, this would involve generating the ID card and updating the database
    final student = _students.firstWhere((s) => s['rollNumber'] == rollNumber);
    final updatedStudent = Map<String, dynamic>.from(student);

    // Mock photoData (replace with actual generation logic)
    updatedStudent['photoData'] = student['photoData'] ?? "mockBase64Data";

    await mongo.MongoDBService.updateUserByRollNumber(rollNumber, updatedStudent);

    // Update the local student list
    setState(() {
      final index = _students.indexWhere((s) => s['rollNumber'] == rollNumber);
      _students[index] = updatedStudent;
      _isGeneratingId[rollNumber] = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ID generated successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
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
        child: _isCreatingForm
            ? _buildFeedbackForm()
            : _isViewingStudents
                ? _buildStudentList()
                : _isViewingFeedback
                    ? _buildFeedbackResponses()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Register New User"),
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
                                        label: 'Email',
                                        icon: Icons.email,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter email';
                                          }
                                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) => _email = value!,
                                      ),
                                      const SizedBox(height: 15),
                                      _buildTextField(
                                        label: 'Password',
                                        icon: Icons.lock,
                                        obscureText: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter password';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) => _password = value!,
                                      ),
                                      const SizedBox(height: 15),
                                      _buildTextField(
                                        label: 'Roll Number',
                                        icon: Icons.badge,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter roll number';
                                          }
                                          return null;
                                        },
                                        onSaved: (value) => _rollNumber = value!,
                                      ),
                                      if (_role != 'student') ...[
                                        const SizedBox(height: 15),
                                        _buildTextField(
                                          label: 'Name',
                                          icon: Icons.person,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter name';
                                            }
                                            return null;
                                          },
                                          onSaved: (value) => _name = value!,
                                        ),
                                      ],
                                      const SizedBox(height: 15),
                                      DropdownButtonFormField<String>(
                                        value: _role,
                                        decoration: const InputDecoration(
                                          labelText: 'Role',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.person),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        items: ['student', 'admin', 'faculty', 'security']
                                            .map((role) => DropdownMenuItem(
                                                  value: role,
                                                  child: Text(role),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() => _role = value!);
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      _isLoading
                                          ? const CircularProgressIndicator()
                                          : _buildElevatedButton(
                                              onPressed: _registerUser,
                                              label: "Register",
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            _buildSectionTitle("Pending Requests"),
                            const SizedBox(height: 20),
                            _pendingRequests.isEmpty
                                ? _buildEmptyMessage("No pending requests")
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _pendingRequests.length,
                                    itemBuilder: (context, index) {
                                      final request = _pendingRequests[index];
                                      final updatedFields = request['updatedFields'] as Map<String, dynamic>;
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
                                                "Student Roll Number: ${request['studentRollNumber']}",
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(height: 10),
                                              Text("Name: ${updatedFields['name']}"),
                                              const SizedBox(height: 5),
                                              Text("Phone: ${updatedFields['phoneNumber']}"),
                                              const SizedBox(height: 5),
                                              Text("Year: ${updatedFields['year'] ?? 'N/A'}"),
                                              const SizedBox(height: 5),
                                              Text("Degree: ${updatedFields['degree'] ?? 'N/A'}"),
                                              const SizedBox(height: 5),
                                              Text("Specialization: ${updatedFields['specialization'] ?? 'N/A'}"),
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  _buildElevatedButton(
                                                    onPressed: () => _approveRequest(request),
                                                    label: "Approve",
                                                    color: Colors.green,
                                                  ),
                                                  _buildElevatedButton(
                                                    onPressed: () => _rejectRequest(request),
                                                    label: "Reject",
                                                    color: Colors.red,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 30),
                            _buildSectionTitle("Access Logs"),
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
                                : _filteredLogs.isEmpty
                                    ? _buildEmptyMessage("No access logs for this date")
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _filteredLogs.length,
                                        itemBuilder: (context, index) {
                                          final log = _filteredLogs[index];
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
                                                        : const AssetImage('assets/default_avatar.png')
                                                            as ImageProvider,
                                                    backgroundColor: Colors.grey.shade200,
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "Student: ${log['studentRollNumber']}",
                                                          style: const TextStyle(
                                                              fontSize: 16, fontWeight: FontWeight.w600),
                                                        ),
                                                        const SizedBox(height: 5),
                                                        Text(
                                                          "Entry: ${log['entryTime'] != null ? log['entryTime'].substring(11, 16) : 'N/A'}",
                                                          style: const TextStyle(fontSize: 14),
                                                        ),
                                                        Text(
                                                          "Exit: ${log['exitTime'] != null ? log['exitTime'].substring(11, 16) : 'N/A'}",
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
                            const SizedBox(height: 30),
                            _buildSectionTitle("Actions"),
                            const SizedBox(height: 20),
                            _buildElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isCreatingForm = true;
                                });
                              },
                              label: "Create Feedback Form",
                            ),
                            const SizedBox(height: 15),
                            _buildElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isViewingStudents = true;
                                });
                              },
                              label: "View Students",
                            ),
                            const SizedBox(height: 15),
                            _buildElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isViewingFeedback = true;
                                });
                              },
                              label: "View Feedback Responses",
                            ),
                            const SizedBox(height: 30),
                            _buildSectionTitle("Face Recognition"),
                            const SizedBox(height: 20),
                            Column(
                              children: [
                                _buildElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RegistrationScreen(),
                                      ),
                                    );
                                  },
                                  label: "Register New Student Via Photo",
                                ),
                                const SizedBox(height: 15),
                                _buildElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RecognitionScreen(),
                                      ),
                                    );
                                  },
                                  label: "Register New Student Via Video",
                                ),
                              ],
                            ),
                          ],
                        ),
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
          children: [
            _buildTextField(
              label: 'Feedback Form Title',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the title';
                }
                return null;
              },
              onSaved: (value) => _title = value!,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Question 1',
              icon: Icons.question_answer,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the first question';
                }
                return null;
              },
              onSaved: (value) => _question1 = value!,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              label: 'Question 2',
              icon: Icons.question_answer,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the second question';
                }
                return null;
              },
              onSaved: (value) => _question2 = value!,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCreatingForm = false;
                    });
                  },
                  label: "Cancel",
                  color: Colors.grey,
                ),
                _buildElevatedButton(
                  onPressed: _createFeedbackForm,
                  label: "Create Form",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle("Student List"),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
                onPressed: () {
                  setState(() {
                    _isViewingStudents = false;
                    _selectedStudent = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _students.isEmpty
              ? _buildEmptyMessage("No students found")
              : _selectedStudent == null
                  ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final rollNumber = student['rollNumber'];
                        final isGenerating = _isGeneratingId[rollNumber] ?? false;
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
                                ListTile(
                                  title: Text(
                                    "Roll Number: ${student['rollNumber']}",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text("Name: ${student['name']}"),
                                  onTap: () {
                                    setState(() {
                                      _selectedStudent = student;
                                    });
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    isGenerating
                                        ? const CircularProgressIndicator()
                                        : _buildElevatedButton(
                                            onPressed: student['photoData'] != null
                                                ? null // Disable button if ID already generated
                                                : () => _generateId(rollNumber),
                                            label: student['photoData'] != null ? "ID Generated" : "Generate ID",
                                            color: student['photoData'] != null ? Colors.grey : Colors.blueAccent,
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Column(
                      children: [
                        if (_selectedStudent!['photoData'] == null)
                          _buildEmptyMessage("ID card not yet generated.")
                        else
                          IdCardWidget(
                            name: _selectedStudent!['name'] ?? 'N/A',
                            rollNumber: _selectedStudent!['rollNumber'] ?? 'N/A',
                            phoneNumber: _selectedStudent!['phoneNumber'] ?? 'N/A',
                            year: _selectedStudent!['year']?.toString() ?? 'N/A',
                            degree: _selectedStudent!['degree']?.toString() ?? 'N/A',
                            specialization: _selectedStudent!['specialization']?.toString() ?? 'N/A',
                            photoData: _selectedStudent!['photoData'],
                            qrCodeId: _selectedStudent!['rollNumber'] ?? '',
                          ),
                        const SizedBox(height: 20),
                        _buildElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedStudent = null;
                            });
                          },
                          label: "Back to List",
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildFeedbackResponses() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle("Feedback Responses"),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
                onPressed: () {
                  setState(() {
                    _isViewingFeedback = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _feedbackResponses.isEmpty
              ? _buildEmptyMessage("No feedback responses available")
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _feedbackResponses.length,
                  itemBuilder: (context, index) {
                    final response = _feedbackResponses[index];
                    final form = _feedbackForms.firstWhere(
                      (form) => form['_id'].toHexString() == response['formId'],
                      orElse: () => {'title': 'Unknown Form', 'questions': ['N/A', 'N/A']},
                    );
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
                              "Form: ${form['title']}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 5),
                            Text("Student Roll Number: ${response['studentRollNumber']}"),
                            const SizedBox(height: 5),
                            Text("Rating: ${response['rating']}"),
                            const SizedBox(height: 5),
                            Text("Comments: ${response['comments']}"),
                            const SizedBox(height: 5),
                            Text("Submitted At: ${response['submittedAt']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
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
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent) : null,
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildElevatedButton({
    required VoidCallback? onPressed,
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
// import 'package:smart_campus_access/models/user.dart';
// import 'package:smart_campus_access/screens/login_screen.dart';
// import 'package:smart_campus_access/screens/recognition_screen.dart';
// import 'package:smart_campus_access/screens/registration_screen.dart';
// import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;
// import 'package:smart_campus_access/widgets/id_card_widget.dart';
// import 'package:mongo_dart/mongo_dart.dart' as mongo_dart; // Alias for mongo_dart to resolve conflict
// import 'dart:convert'; // For base64 decoding

// class AdminScreen extends StatefulWidget {
//   final Map<String, dynamic> user;

//   const AdminScreen({Key? key, required this.user}) : super(key: key);

//   @override
//   State<AdminScreen> createState() => _AdminScreenState();
// }

// class _AdminScreenState extends State<AdminScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _feedbackFormKey = GlobalKey<FormState>();
//   String _email = '';
//   String _password = '';
//   String _rollNumber = '';
//   String _name = '';
//   String _role = 'student';
//   String _title = '';
//   String _question1 = '';
//   String _question2 = '';
//   bool _isLoading = false;
//   bool _isCreatingForm = false;
//   bool _isViewingStudents = false;
//   bool _isViewingFeedback = false;
//   List<Map<String, dynamic>> _pendingRequests = [];
//   List<Map<String, dynamic>> _students = [];
//   List<Map<String, dynamic>> _feedbackForms = [];
//   List<Map<String, dynamic>> _feedbackResponses = [];
//   List<Map<String, dynamic>> _accessLogs = [];
//   DateTime? _selectedDate;
//   List<Map<String, dynamic>> _filteredLogs = [];
//   Map<String, dynamic>? _selectedStudent;

//   @override
//   void initState() {
//     super.initState();
//     _fetchPendingRequests();
//     _fetchStudents();
//     _fetchFeedbackForms();
//     _fetchFeedbackResponses();
//     _fetchAccessLogs();
//   }

//   Future<void> _fetchPendingRequests() async {
//     final requests = await mongo.MongoDBService.getPendingRequests();
//     setState(() {
//       _pendingRequests = requests;
//     });
//   }

//   Future<void> _fetchStudents() async {
//     final students = await mongo.MongoDBService.getAllStudents();
//     setState(() {
//       _students = students;
//     });
//   }

//   Future<void> _fetchFeedbackForms() async {
//     final forms = await mongo.MongoDBService.getAllFeedbackForms();
//     setState(() {
//       _feedbackForms = forms;
//     });
//   }

//   Future<void> _fetchFeedbackResponses() async {
//     final responses = await mongo.MongoDBService.getAllFeedbackResponses();
//     setState(() {
//       _feedbackResponses = responses;
//     });
//   }

//   Future<void> _fetchAccessLogs() async {
//     final logs = await mongo.MongoDBService.getAccessLogs();
//     setState(() {
//       _accessLogs = logs;
//       if (_selectedDate != null) {
//         _filterLogsByDate();
//       }
//     });
//   }

//   Future<void> _registerUser() async {
//     if (_formKey.currentState!.validate()) {
//       _formKey.currentState!.save();
//       setState(() => _isLoading = true);

//       final existingUser = await mongo.MongoDBService.getUserByRollNumber(_rollNumber);
//       if (existingUser != null) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("A user with this roll number already exists.")),
//         );
//         return;
//       }

//       final user = User(
//         email: _email,
//         password: _password,
//         role: _role,
//         rollNumber: _rollNumber,
//         name: _role != 'student' ? _name : null,
//       ).toMap();

//       await mongo.MongoDBService.insertUser(user);
//       setState(() => _isLoading = false);

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("User registered successfully")),
//       );

//       _formKey.currentState!.reset();
//     }
//   }

//   Future<void> _createFeedbackForm() async {
//     if (_feedbackFormKey.currentState!.validate()) {
//       _feedbackFormKey.currentState!.save();

//       final feedbackForm = {
//         'title': _title,
//         'questions': [_question1, _question2],
//         'createdAt': DateTime.now().toIso8601String(),
//       };

//       await mongo.MongoDBService.createFeedbackForm(feedbackForm);
//       await _fetchFeedbackForms();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Feedback form created successfully")),
//       );

//       setState(() {
//         _isCreatingForm = false;
//         _title = '';
//         _question1 = '';
//         _question2 = '';
//       });
//     }
//   }

//   Future<void> _approveRequest(Map<String, dynamic> request) async {
//     final rollNumber = request['studentRollNumber'];
//     final updatedFields = request['updatedFields'] as Map<String, dynamic>;

//     // Fetch the original student data
//     final student = await mongo.MongoDBService.getUserByRollNumber(rollNumber);
//     if (student == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Student not found")),
//       );
//       return;
//     }

//     // Use original student data as fallback for null values in updatedFields
//     final updatedUser = {
//       'name': updatedFields['name'] ?? student['name'] ?? 'N/A',
//       'phoneNumber': updatedFields['phoneNumber'] ?? student['phoneNumber'] ?? 'N/A',
//       'year': updatedFields['year'] ?? student['year'] ?? 'N/A',
//       'degree': updatedFields['degree'] ?? student['degree'] ?? 'N/A',
//       'specialization': updatedFields['specialization'] ?? student['specialization'] ?? 'N/A',
//     };

//     await mongo.MongoDBService.updateUserByRollNumber(rollNumber, updatedUser);
//     final requestId = request['_id'] as mongo_dart.ObjectId;
//     await mongo.MongoDBService.updateRequestStatus(requestId, 'approved');
//     await _fetchPendingRequests();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Request approved and user updated")),
//     );
//   }

//   Future<void> _rejectRequest(Map<String, dynamic> request) async {
//     final requestId = request['_id'] as mongo_dart.ObjectId;
//     await mongo.MongoDBService.updateRequestStatus(requestId, 'rejected');
//     await _fetchPendingRequests();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Request rejected")),
//     );
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
//         _filterLogsByDate();
//       });
//     }
//   }

//   void _filterLogsByDate() {
//     if (_selectedDate == null) {
//       _filteredLogs = [];
//       return;
//     }

//     final selectedDateStr = _selectedDate!.toIso8601String().substring(0, 10); // YYYY-MM-DD
//     final Map<String, Map<String, dynamic>> consolidatedLogs = {};

//     for (var log in _accessLogs) {
//       final logDate = log['timestamp'].substring(0, 10);
//       if (logDate == selectedDateStr) {
//         final studentRollNumber = log['studentRollNumber'];
//         if (!consolidatedLogs.containsKey(studentRollNumber)) {
//           consolidatedLogs[studentRollNumber] = {
//             'studentRollNumber': studentRollNumber,
//             'entryTime': null,
//             'exitTime': null,
//             'photoData': null,
//           };
//           _fetchStudentPhoto(studentRollNumber).then((photoData) {
//             setState(() {
//               consolidatedLogs[studentRollNumber]!['photoData'] = photoData;
//             });
//           });
//         }
//         if (log['action'] == 'entry') {
//           consolidatedLogs[studentRollNumber]!['entryTime'] = log['timestamp'];
//         } else if (log['action'] == 'exit') {
//           consolidatedLogs[studentRollNumber]!['exitTime'] = log['timestamp'];
//         }
//       }
//     }

//     setState(() {
//       _filteredLogs = consolidatedLogs.values.toList();
//     });
//   }

//   Future<String?> _fetchStudentPhoto(String rollNumber) async {
//     final user = await mongo.MongoDBService.getUserByRollNumber(rollNumber);
//     return user?['photoData'];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Admin Dashboard",
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
//         child: _isCreatingForm
//             ? _buildFeedbackForm()
//             : _isViewingStudents
//                 ? _buildStudentList()
//                 : _isViewingFeedback
//                     ? _buildFeedbackResponses()
//                     : SingleChildScrollView(
//                         padding: const EdgeInsets.all(20),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildSectionTitle("Register New User"),
//                             const SizedBox(height: 20),
//                             Card(
//                               elevation: 8,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(20),
//                                 child: Form(
//                                   key: _formKey,
//                                   child: Column(
//                                     children: [
//                                       _buildTextField(
//                                         label: 'Email',
//                                         icon: Icons.email,
//                                         keyboardType: TextInputType.emailAddress,
//                                         validator: (value) {
//                                           if (value == null || value.isEmpty) {
//                                             return 'Please enter email';
//                                           }
//                                           if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                                             return 'Please enter a valid email';
//                                           }
//                                           return null;
//                                         },
//                                         onSaved: (value) => _email = value!,
//                                       ),
//                                       const SizedBox(height: 15),
//                                       _buildTextField(
//                                         label: 'Password',
//                                         icon: Icons.lock,
//                                         obscureText: true,
//                                         validator: (value) {
//                                           if (value == null || value.isEmpty) {
//                                             return 'Please enter password';
//                                           }
//                                           return null;
//                                         },
//                                         onSaved: (value) => _password = value!,
//                                       ),
//                                       const SizedBox(height: 15),
//                                       _buildTextField(
//                                         label: 'Roll Number',
//                                         icon: Icons.badge,
//                                         validator: (value) {
//                                           if (value == null || value.isEmpty) {
//                                             return 'Please enter roll number';
//                                           }
//                                           return null;
//                                         },
//                                         onSaved: (value) => _rollNumber = value!,
//                                       ),
//                                       if (_role != 'student') ...[
//                                         const SizedBox(height: 15),
//                                         _buildTextField(
//                                           label: 'Name',
//                                           icon: Icons.person,
//                                           validator: (value) {
//                                             if (value == null || value.isEmpty) {
//                                               return 'Please enter name';
//                                             }
//                                             return null;
//                                           },
//                                           onSaved: (value) => _name = value!,
//                                         ),
//                                       ],
//                                       const SizedBox(height: 15),
//                                       DropdownButtonFormField<String>(
//                                         value: _role,
//                                         decoration: const InputDecoration(
//                                           labelText: 'Role',
//                                           border: OutlineInputBorder(),
//                                           prefixIcon: Icon(Icons.person),
//                                           filled: true,
//                                           fillColor: Colors.white,
//                                         ),
//                                         items: ['student', 'admin', 'faculty', 'security']
//                                             .map((role) => DropdownMenuItem(
//                                                   value: role,
//                                                   child: Text(role),
//                                                 ))
//                                             .toList(),
//                                         onChanged: (value) {
//                                           setState(() => _role = value!);
//                                         },
//                                       ),
//                                       const SizedBox(height: 20),
//                                       _isLoading
//                                           ? const CircularProgressIndicator()
//                                           : _buildElevatedButton(
//                                               onPressed: _registerUser,
//                                               label: "Register",
//                                             ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 30),
//                             _buildSectionTitle("Pending Requests"),
//                             const SizedBox(height: 20),
//                             _pendingRequests.isEmpty
//                                 ? _buildEmptyMessage("No pending requests")
//                                 : ListView.builder(
//                                     shrinkWrap: true,
//                                     physics: const NeverScrollableScrollPhysics(),
//                                     itemCount: _pendingRequests.length,
//                                     itemBuilder: (context, index) {
//                                       final request = _pendingRequests[index];
//                                       final updatedFields = request['updatedFields'] as Map<String, dynamic>;
//                                       return Card(
//                                         elevation: 5,
//                                         margin: const EdgeInsets.symmetric(vertical: 10),
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(15),
//                                         ),
//                                         child: Padding(
//                                           padding: const EdgeInsets.all(15),
//                                           child: Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 "Student Roll Number: ${request['studentRollNumber']}",
//                                                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                                               ),
//                                               const SizedBox(height: 10),
//                                               Text("Name: ${updatedFields['name']}"),
//                                               const SizedBox(height: 5),
//                                               Text("Phone: ${updatedFields['phoneNumber']}"),
//                                               const SizedBox(height: 5),
//                                               Text("Year: ${updatedFields['year'] ?? 'N/A'}"),
//                                               const SizedBox(height: 5),
//                                               Text("Degree: ${updatedFields['degree'] ?? 'N/A'}"),
//                                               const SizedBox(height: 5),
//                                               Text("Specialization: ${updatedFields['specialization'] ?? 'N/A'}"),
//                                               const SizedBox(height: 10),
//                                               Row(
//                                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                                 children: [
//                                                   _buildElevatedButton(
//                                                     onPressed: () => _approveRequest(request),
//                                                     label: "Approve",
//                                                     color: Colors.green,
//                                                   ),
//                                                   _buildElevatedButton(
//                                                     onPressed: () => _rejectRequest(request),
//                                                     label: "Reject",
//                                                     color: Colors.red,
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                             const SizedBox(height: 30),
//                             _buildSectionTitle("Access Logs"),
//                             const SizedBox(height: 20),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   _selectedDate == null
//                                       ? "Select a date to view logs"
//                                       : "Logs for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
//                                   style: const TextStyle(fontSize: 16, color: Colors.black54),
//                                 ),
//                                 _buildElevatedButton(
//                                   onPressed: () => _selectDate(context),
//                                   label: "Pick Date",
//                                   color: Colors.blueAccent,
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 20),
//                             _selectedDate == null
//                                 ? _buildEmptyMessage("Please select a date to view logs")
//                                 : _filteredLogs.isEmpty
//                                     ? _buildEmptyMessage("No access logs for this date")
//                                     : ListView.builder(
//                                         shrinkWrap: true,
//                                         physics: const NeverScrollableScrollPhysics(),
//                                         itemCount: _filteredLogs.length,
//                                         itemBuilder: (context, index) {
//                                           final log = _filteredLogs[index];
//                                           return Card(
//                                             elevation: 5,
//                                             margin: const EdgeInsets.symmetric(vertical: 10),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius: BorderRadius.circular(15),
//                                             ),
//                                             child: Padding(
//                                               padding: const EdgeInsets.all(15),
//                                               child: Row(
//                                                 children: [
//                                                   CircleAvatar(
//                                                     radius: 30,
//                                                     backgroundImage: log['photoData'] != null
//                                                         ? MemoryImage(base64Decode(log['photoData']))
//                                                         : const AssetImage('assets/default_avatar.png')
//                                                             as ImageProvider,
//                                                     backgroundColor: Colors.grey.shade200,
//                                                   ),
//                                                   const SizedBox(width: 15),
//                                                   Expanded(
//                                                     child: Column(
//                                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                                       children: [
//                                                         Text(
//                                                           "Student: ${log['studentRollNumber']}",
//                                                           style: const TextStyle(
//                                                               fontSize: 16, fontWeight: FontWeight.w600),
//                                                         ),
//                                                         const SizedBox(height: 5),
//                                                         Text(
//                                                           "Entry: ${log['entryTime'] != null ? log['entryTime'].substring(11, 16) : 'N/A'}",
//                                                           style: const TextStyle(fontSize: 14),
//                                                         ),
//                                                         Text(
//                                                           "Exit: ${log['exitTime'] != null ? log['exitTime'].substring(11, 16) : 'N/A'}",
//                                                           style: const TextStyle(fontSize: 14),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                             const SizedBox(height: 30),
//                             _buildSectionTitle("Actions"),
//                             const SizedBox(height: 20),
//                             _buildElevatedButton(
//                               onPressed: () {
//                                 setState(() {
//                                   _isCreatingForm = true;
//                                 });
//                               },
//                               label: "Create Feedback Form",
//                             ),
//                             const SizedBox(height: 15),
//                             _buildElevatedButton(
//                               onPressed: () {
//                                 setState(() {
//                                   _isViewingStudents = true;
//                                 });
//                               },
//                               label: "View Students",
//                             ),
//                             const SizedBox(height: 15),
//                             _buildElevatedButton(
//                               onPressed: () {
//                                 setState(() {
//                                   _isViewingFeedback = true;
//                                 });
//                               },
//                               label: "View Feedback Responses",
//                             ),
//                             const SizedBox(height: 30),
//                             _buildSectionTitle("Face Recognition"),
//                             const SizedBox(height: 20),
//                             Column(
//                               children: [
//                                 _buildElevatedButton(
//                                   onPressed: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => RegistrationScreen(),
//                                       ),
//                                     );
//                                   },
//                                   label: "Register New Student Via Photo",
//                                 ),
//                                 const SizedBox(height: 15),
//                                 _buildElevatedButton(
//                                   onPressed: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (context) => RecognitionScreen(),
//                                       ),
//                                     );
//                                   },
//                                   label: "Register New Student Via Video",
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//       ),
//     );
//   }

//   Widget _buildFeedbackForm() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Form(
//         key: _feedbackFormKey,
//         child: Column(
//           children: [
//             _buildTextField(
//               label: 'Feedback Form Title',
//               icon: Icons.title,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter the title';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _title = value!,
//             ),
//             const SizedBox(height: 15),
//             _buildTextField(
//               label: 'Question 1',
//               icon: Icons.question_answer,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter the first question';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _question1 = value!,
//             ),
//             const SizedBox(height: 15),
//             _buildTextField(
//               label: 'Question 2',
//               icon: Icons.question_answer,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter the second question';
//                 }
//                 return null;
//               },
//               onSaved: (value) => _question2 = value!,
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       _isCreatingForm = false;
//                     });
//                   },
//                   label: "Cancel",
//                   color: Colors.grey,
//                 ),
//                 _buildElevatedButton(
//                   onPressed: _createFeedbackForm,
//                   label: "Create Form",
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStudentList() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildSectionTitle("Student List"),
//               IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
//                 onPressed: () {
//                   setState(() {
//                     _isViewingStudents = false;
//                     _selectedStudent = null;
//                   });
//                 },
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           _students.isEmpty
//               ? _buildEmptyMessage("No students found")
//               : _selectedStudent == null
//                   ? ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: _students.length,
//                       itemBuilder: (context, index) {
//                         final student = _students[index];
//                         return Card(
//                           elevation: 5,
//                           margin: const EdgeInsets.symmetric(vertical: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: ListTile(
//                             title: Text(
//                               "Roll Number: ${student['rollNumber']}",
//                               style: const TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                             subtitle: Text("Name: ${student['name']}"),
//                             onTap: () {
//                               setState(() {
//                                 _selectedStudent = student;
//                               });
//                             },
//                           ),
//                         );
//                       },
//                     )
//                   : Column(
//                       children: [
//                         if (_selectedStudent!['photoData'] == null)
//                           _buildEmptyMessage("ID card not yet generated.")
//                         else
//                           IdCardWidget(
//                             name: _selectedStudent!['name'] ?? 'N/A',
//                             rollNumber: _selectedStudent!['rollNumber'] ?? 'N/A',
//                             phoneNumber: _selectedStudent!['phoneNumber'] ?? 'N/A',
//                             year: _selectedStudent!['year']?.toString() ?? 'N/A',
//                             degree: _selectedStudent!['degree']?.toString() ?? 'N/A',
//                             specialization: _selectedStudent!['specialization']?.toString() ?? 'N/A',
//                             photoData: _selectedStudent!['photoData'],
//                             qrCodeId: _selectedStudent!['rollNumber'] ?? '',
//                           ),
//                         const SizedBox(height: 20),
//                         _buildElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               _selectedStudent = null;
//                             });
//                           },
//                           label: "Back to List",
//                         ),
//                       ],
//                     ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeedbackResponses() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildSectionTitle("Feedback Responses"),
//               IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
//                 onPressed: () {
//                   setState(() {
//                     _isViewingFeedback = false;
//                   });
//                 },
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           _feedbackResponses.isEmpty
//               ? _buildEmptyMessage("No feedback responses available")
//               : ListView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: _feedbackResponses.length,
//                   itemBuilder: (context, index) {
//                     final response = _feedbackResponses[index];
//                     final form = _feedbackForms.firstWhere(
//                       (form) => form['_id'].toHexString() == response['formId'],
//                       orElse: () => {'title': 'Unknown Form', 'questions': ['N/A', 'N/A']},
//                     );
//                     return Card(
//                       elevation: 5,
//                       margin: const EdgeInsets.symmetric(vertical: 10),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(15),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Form: ${form['title']}",
//                               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                             ),
//                             const SizedBox(height: 5),
//                             Text("Student Roll Number: ${response['studentRollNumber']}"),
//                             const SizedBox(height: 5),
//                             Text("Rating: ${response['rating']}"),
//                             const SizedBox(height: 5),
//                             Text("Comments: ${response['comments']}"),
//                             const SizedBox(height: 5),
//                             Text("Submitted At: ${response['submittedAt']}"),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//         ],
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
//     IconData? icon,
//     bool obscureText = false,
//     TextInputType? keyboardType,
//     required String? Function(String?) validator,
//     required void Function(String?) onSaved,
//   }) {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent) : null,
//         filled: true,
//         fillColor: Colors.white,
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
//         ),
//       ),
//       obscureText: obscureText,
//       keyboardType: keyboardType,
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

