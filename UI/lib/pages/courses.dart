import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_campus_access/services/mongodb_service.dart' as mongo;
import 'package:smart_campus_access/pages/schedule.dart' show SchedulePage;



class Courses extends StatefulWidget {
  final Map<String, dynamic> user;
  const Courses({Key? key, required this.user}) : super(key: key);
  @override
  _CourseState createState() => _CourseState();
}


class _CourseState extends State<Courses> {
  bool _isFetchingCourses = false;
  Set<String> _loadingLinks = {};
  List<Map<String, dynamic>> courses = [];
  late String _rollNumber;

  @override
  void initState() {
    super.initState();
    _rollNumber = widget.user['rollNumber'] ?? 'N/A';
    _fetchCourses();
  }
  Future<void> _fetchCourses() async {
    try {
      setState(() {
        _isFetchingCourses = true;
      });
      final _courses = await mongo.MongoDBService.getCoursesForStudent(_rollNumber);
      setState(() {
        courses = _courses;
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text("Courses",style:TextStyle(color:Colors.white)),
        centerTitle: true,
      ),
      
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            
            courses.isEmpty ? buildNoCoursesCard():SizedBox(height: 0),
            SizedBox(height: 12),
            Column(
              children: courses.map((course) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Text(course["courseName"]!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text(course["courseCode"]!),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: 
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _launchURL(course['resources']['syllabusLink']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xCCB24507),
                                ),
                                child: Container(
                                  width: screenWidth, height: 20,
                                  alignment: Alignment.center,
                                  child: Text('View full syllabus', style: TextStyle(color: Colors.white))
                                  ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                    _launchURL(course['resources']['scheduleLink']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xCCB24507),
                                ),
                                child: Container(
                                  width: screenWidth, height: 20,
                                  alignment: Alignment.center,
                                  child: Text('Class Schedule', style: TextStyle(color: Colors.white))
                                  ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                    _launchURL(course['resources']['materialsLink']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xCCB24507),
                                ),
                                child: Container(
                                  width: screenWidth, height: 20,
                                  alignment: Alignment.center,
                                  child: Text('Additional Materials', style: TextStyle(color: Colors.white))
                                  ),
                              )
                            ]
                          )
                          
                        )
                        
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildNoCoursesCard() {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "You currently have no assigned courses.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


}
