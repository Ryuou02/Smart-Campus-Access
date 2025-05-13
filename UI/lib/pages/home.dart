import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:smart_campus_access/pages/courses.dart' show Courses;
import 'package:smart_campus_access/pages/profileEdit.dart' show ProfileEditPage;
import 'package:smart_campus_access/pages/schedule.dart' show SchedulePage;
import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;
class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isEditing = false;
  bool _isFillingFeedback = false;
  Map<String, dynamic>? _selectedForm;
  final _formKey = GlobalKey<FormState>();
  final _feedbackFormKey = GlobalKey<FormState>();
  late String _name;
  late String _phoneNumber;
  late String _rollNumber;
  late String _year;
  late String _degree;
  late String _specialization;
  late String? _photoData; // Changed to photoData
  late String _qrCodeId;
  String _comments = '';
  late Map<String, dynamic> user;
  List<Map<String, dynamic>> _feedbackForms = [];

  @override
  void initState() {
    super.initState();
    this.user=widget.user;
    _name = widget.user['name'] ?? 'N/A';
    _phoneNumber = widget.user['phoneNumber'] ?? 'N/A';
    _rollNumber = widget.user['rollNumber'] ?? 'N/A';
    _year = widget.user['year'] ?? 'N/A';
    _degree = widget.user['degree'] ?? 'N/A';
    _specialization = widget.user['specialization'] ?? 'N/A';
    _photoData = widget.user['photoData']; // Changed to photoData
    _qrCodeId = widget.user['qrCodeId'] ?? '';
    _fetchFeedbackForms();
  }
  Future<void> _fetchFeedbackForms() async {
    final forms = await mongo.MongoDBService.getAllFeedbackForms(); 
    setState(() {
      _feedbackForms = forms;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text("Home"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture
            Center(
              child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _photoData != null
                          ? Image.memory(
                              base64Decode(_photoData!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                    )
            ),
            SizedBox(height: 24),

            // Announcements Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Announcements",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            SizedBox(height: 12),
            Column(
                children: _feedbackForms.map((notification) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification["title"]!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text(notification["questions"][0]!),
                          SizedBox(height: 8),
                          Text(notification["questions"][1]!),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _feedbackForms.remove(notification);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xCCB24507),
                              ),
                              child: Text("Acknowledge", style: TextStyle(color: Colors.white)),
                            ),
                          )
                        ],
                      ) ,
                    ),
                  );
                }).toList()
              ),
              _qrCodeId.isNotEmpty ? Card(margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Attendance QR code", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          SizedBox(height: 4),
                          Text("show this qr code to security at the gate"),
                          SizedBox(height: 8),
                          QrImageView(
                            data: _qrCodeId,
                            version: QrVersions.auto,
                            size: 100.0,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(5),
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.blueAccent,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.blueAccent,
                            ),
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _qrCodeId = "";
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xCCB24507),
                              ),
                              child: Text("Acknowledge", style: TextStyle(color: Colors.white)),
                            ),
                          )
                        ],
                      ) ,
                    )):SizedBox(height: 2),

            SizedBox(height: 20),

            // Navigation Buttons
            buildBigButton(context, "Profile Edit", (context) => ProfileEditPage(user: user)),
            buildBigButton(context, "View Courses",(context) => Courses(user:user)),
          ],
        ),
      ),
    );
  }
  Widget buildBigButton(
    BuildContext context,
    String title,
    WidgetBuilder builder,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          try {
            Navigator.push(context, MaterialPageRoute(builder: builder));
          } catch (e, stackTrace) {
            print('Navigation error: $e');
            print(stackTrace);
          }
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Color(0xCCB24507),
        ),
        child: Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
