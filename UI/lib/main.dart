import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_campus_access/pages/login.dart' show LoginPage;
import 'package:smart_campus_access/services/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoDBService.connect();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Campus Access',
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/icon.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
