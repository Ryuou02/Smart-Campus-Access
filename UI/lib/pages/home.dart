import 'package:flutter/material.dart';
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> notifications = [
    {
      "title": "Welcome!",
      "description": "Thank you for joining our platform."
    },
    {
      "title": "Course Update",
      "description": "Your schedule has been updated."
    },
    {
      "title": "Reminder",
      "description": "Upload your documents before Friday."
    }
  ];

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
              child: Container(
                width: screenWidth * 0.75,
                height: screenWidth * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/profile.png'), // Add your image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
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
              children: notifications.map((notification) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification["title"]!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text(notification["description"]!),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                notifications.remove(notification);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xCCB24507),
                            ),
                            child: Text("Acknowledge"),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            // Navigation Buttons
            buildBigButton(context, "Profile Edit"),
            buildBigButton(context, "View Courses"),
            buildBigButton(context, "Schedule"),
            buildBigButton(context, "Documents"),
            buildBigButton(context, "Raise Request"),
          ],
        ),
      ),
    );
  }

  Widget buildBigButton(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          // Handle navigation
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Color(0xCCB24507),
        ),
        child: Text(title, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
