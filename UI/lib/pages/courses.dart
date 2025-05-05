import 'package:flutter/material.dart';
import 'package:smart_campus_access/pages/schedule.dart' show SchedulePage;

class Courses extends StatefulWidget {
  @override
  _CourseState createState() => _CourseState();
}


class _CourseState extends State<Courses> {
  List<Map<String, String>> courses = [
    {
      "title": "course 1",
      "description": "19cse203"
    },
    {
      "title": "course2",
      "description": "10cse308"
    },
    {
      "title": "course 3",
      "description": "100cse314"
    }
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: Text("Courses"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            
            
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
                        Text(course["title"]!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text(course["description"]!),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: 
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // do nothing
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
                                 Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SchedulePage()),
                                  );
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
                                    // do nothing
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

}
